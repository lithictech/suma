# frozen_string_literal: true

RSpec.describe "Suma::UploadedFile", :db do
  let(:described_class) { Suma::UploadedFile }

  before(:each) do
    described_class.drop_blobs_table
    described_class.ensure_blobs_table
  end

  after(:each) do
    described_class.drop_blobs_table
    described_class.ensure_blobs_table
  end

  describe "create_with_blob" do
    it "can create a new blob and image" do
      got = described_class.create_with_blob(bytes: png_1x1, content_type: "image/png")
      expect(got.values).to include(
        sha256: "4162c89ce573251b6b77c9f6cb627ba15ffdcd0fb11e06716e40f4ea0dd66f15",
        opaque_id: start_with("im_"),
        content_length: 497,
        content_type: "image/png",
      )
      expect(got.blob_stream.read).to eq(png_1x1)
    end

    it "upserts the blob" do
      described_class.create_with_blob(bytes: png_1x1, content_type: "image/png")
      expect(described_class.blob_dataset.all).to have_length(1)
      described_class.create_with_blob(bytes: png_1x1, content_type: "image/jpeg")
      expect(described_class.blob_dataset.all).to have_length(1)
    end
  end

  describe "create_from_multipart" do
    it "creates the image from Rack params" do
      got = described_class.create_from_multipart({tempfile: StringIO.new(png_1x1), type: "ct"})
      expect(got.values).to include(
        sha256: "4162c89ce573251b6b77c9f6cb627ba15ffdcd0fb11e06716e40f4ea0dd66f15",
        content_type: "ct",
        filename: "#{got.opaque_id}.ct",
      )
    end

    it "defaults to detect the content type from the filename" do
      got = described_class.create_from_multipart({tempfile: StringIO.new(png_1x1), filename: "foo.png"})
      expect(got.values).to include(
        content_type: "image/png",
        filename: "foo.png",
      )
    end
  end

  describe "blob_stream" do
    it "is cached" do
      uf = described_class.create_with_blob(bytes: png_1x1, content_type: "image/png")
      uf.blob_stream.read
      described_class.drop_blobs_table
      expect { uf.blob_stream.read }.to_not raise_error
    end

    it "refetches if the fetched sha has changed" do
      uf = described_class.create_with_blob(bytes: png_1x1, content_type: "image/png")
      uf.blob_stream.read
      described_class.drop_blobs_table
      uf.sha256 = "changed"
      expect { uf.blob_stream.read }.to raise_error(Sequel::DatabaseError)
    end

    it "raises if there is no blob" do
      uf = Suma::Fixtures.uploaded_file.create
      expect { uf.blob_stream }.to raise_error(described_class::MissingBlob)
    end
  end

  let(:png_1x1) { Suma::Fixtures::UploadedFiles::PNG_1X1_BYTES }
end
