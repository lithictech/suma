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

  describe "configuration" do
    it "can create a plain table" do
      described_class.blob_database << "DROP TABLE IF EXISTS uploaded_file_cfg_test"
      described_class.blob_table = "uploaded_file_cfg_test"
      described_class.run_after_configured_hooks
      expect(described_class.blob_dataset.all).to be_empty
    end

    it "can create a schema and table" do
      described_class.blob_database << "DROP SCHEMA IF EXISTS uploaded_file_testschema CASCADE"
      described_class.blob_table = "uploaded_file_testschema.testtable"
      described_class.run_after_configured_hooks
      expect(described_class.blob_dataset.all).to be_empty
    end
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
      expect(described_class.dataset.all).to have_length(1)
      # Ensure we only get one insert per-blob, no matter how many uploaded files we have.
      described_class.create_with_blob(bytes: png_1x1, content_type: "image/jpeg", validate: false)
      expect(described_class.blob_dataset.all).to have_length(1)
      expect(described_class.dataset.all).to have_length(2)
    end

    it "errors if the bytes and given content type have unmatched, unsafe content types" do
      expect do
        described_class.create_with_blob(bytes: png_1x1, content_type: "image/jpeg")
      end.to raise_error(described_class::MismatchedContentType)
      described_class.create_with_blob(bytes: "abc", content_type: "text/plain")
      described_class.create_with_blob(bytes: "abc", content_type: "text/html")
      described_class.create_with_blob(bytes: "<x></x>", content_type: "text/html")
      described_class.create_with_blob(bytes: "<html></html>", content_type: "text/html")
      described_class.create_with_blob(bytes: "<x></x>", content_type: "text/plain")
      expect do
        described_class.create_with_blob(bytes: png_1x1, content_type: "text/plain")
      end.to raise_error(described_class::MismatchedContentType)
      expect do
        described_class.create_with_blob(bytes: "<html></html>", content_type: "application/javascript")
      end.to raise_error(described_class::MismatchedContentType)
      expect do
        described_class.create_with_blob(bytes: png_1x1, content_type: "application/javascript")
      end.to raise_error(described_class::MismatchedContentType)
    end
  end

  describe "create_from_multipart" do
    it "creates the image from Rack params" do
      got = described_class.create_from_multipart({tempfile: StringIO.new(png_1x1), type: "image/png"})
      expect(got.values).to include(
        sha256: "4162c89ce573251b6b77c9f6cb627ba15ffdcd0fb11e06716e40f4ea0dd66f15",
        content_type: "image/png",
        filename: "#{got.opaque_id}.png",
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

    it "errors if the file is private and it has not been unlocked" do
      uf = described_class.create_with_blob(bytes: png_1x1, content_type: "image/png")
      uf.private = true
      expect { uf.blob_stream }.to raise_error(described_class::PrivateFile)
      uf.unlock_blob
      expect { uf.blob_stream }.to_not raise_error
    end
  end

  describe "validations" do
    it "must have a creator if private" do
      uf = Suma::Fixtures.uploaded_file.instance
      uf.private = true
      uf.created_by = nil
      uf.validate
      expect(uf.errors).to include(private: ["created_by must be set"])

      uf = Suma::Fixtures.uploaded_file.instance
      uf.private = true
      uf.created_by = Suma::Fixtures.member.create
      uf.validate
      expect(uf.errors).to be_empty
    end

    it "does not allow changes once saved" do
      uf = Suma::Fixtures.uploaded_file.create
      expect { uf.update(filename: "foo") }.to raise_error(FrozenError)
    end

    it "requires the filename and content type to be compatible" do
      uf = Suma::Fixtures.uploaded_file.create
      uf.filename = "foo.png"
      uf.content_type = "image/jpeg"
      uf.validate
      expect(uf.errors).to include(filename: [".png content type 'image/png' must match 'image/jpeg'"])

      uf.errors.clear
      uf.filename = "foo"
      uf.content_type = "image/jpeg"
      uf.validate
      expect(uf.errors).to be_empty

      uf.errors.clear
      uf.filename = "foo.csv"
      uf.content_type = "text/plain"
      uf.validate
      expect(uf.errors).to be_empty

      uf.errors.clear
      uf.filename = "foo.csv"
      uf.content_type = "text/html"
      uf.validate
      expect(uf.errors).to include(filename: [".csv content type 'text/csv' must match 'text/html'"])

      # .html gets a content type of application/xhtml+xml from MimeMagic by default.
      # Make sure .html works with various xml content types.
      html_content_types = ["text/html", "application/xhtml+xml"]
      html_content_types.each do |ct|
        uf.errors.clear
        uf.filename = "foo.html"
        uf.content_type = ct
        uf.validate
        expect(uf.errors).to be_empty
      end
    end
  end

  describe "NoImageAvailable" do
    it "is like a normal uploaded file" do
      expect(described_class::NoImageAvailable.new).to have_attributes(
        blob_stream: be_a(StringIO),
        absolute_url: be_a(String),
        opaque_id: "missing",
        filename: "no-image-available.png",
        sha256: "b6a6e1dfff4e812d9c224cd427e1b65936e952db39ea8c6e638e6de21620872d",
        content_type: "image/png",
        content_length: 37_331,
      )
    end
  end

  let(:png_1x1) { Suma::SpecHelpers::PNG_1X1_BYTES }
end
