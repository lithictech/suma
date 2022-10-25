# frozen_string_literal: true

require "suma/image_processor"

RSpec.describe Suma::ImageProcessor do
  let(:photo_filename) { Suma::SpecHelpers::TEST_DATA_DIR + "images/photo.png" }
  def photo_file = File.open(photo_filename, "rb")

  describe "from_buffer" do
    it "loads an image source from a buffer" do
      img = described_class.from_buffer(Suma::Fixtures::UploadedFiles::PNG_1X1_BYTES)
      expect(img.size).to eq([1, 1])
    end
  end

  describe "from_file" do
    it "loads an image source from a file" do
      img = described_class.from_file(photo_file)
      expect(img.size).to eq([128, 128])
    end
  end

  describe "handle" do
    def handle(**opts)
      v = described_class.prepare(described_class.from_file(photo_file), **opts)
      return v.call(save: false)
    end

    it "handles absolute resizing" do
      expect(handle(w: 10).size).to eq([10, 128])
      expect(handle(h: 10).size).to eq([128, 10])
      expect(handle(w: 11, h: 10).size).to eq([11, 10])
    end

    it "handles proportional resizing" do
      expect(handle(w: 0.5).size).to eq([64, 128])
      expect(handle(h: 0.5).size).to eq([128, 64])
      expect(handle(w: 0.25, h: 0.5).size).to eq([32, 64])
      expect(handle(w: 1, h: 0.5).size).to eq([128, 64])
    end

    it "errors for an invalid dimension" do
      expect { handle(w: 0) }.to raise_error(described_class::InvalidOption)
      expect { handle(h: 0) }.to raise_error(described_class::InvalidOption)
    end

    it "can resize limit" do
      expect(handle(w: 0.5, resize: :limit).size).to eq([64, 128])
    end

    it "can resize fill" do
      expect(handle(w: 0.5, resize: :fill).size).to eq([64, 64])
    end

    it "raises for an unknown resize" do
      expect { handle(w: 10, resize: :foo) }.to raise_error(described_class::InvalidOption)
    end

    it "can convert format" do
      expect(described_class.process(file: photo_file, format: :png)).to have_length(be > 40_000)
      expect(described_class.process(file: photo_file, format: :jpeg)).to have_length(be < 20_000)
      expect(described_class.process(file: photo_file, format: :jpeg, quality: 100)).to have_length(be > 20_000)
    end

    it "errors for an invalid format" do
      expect { handle(format: "jpeg") }.to raise_error(described_class::InvalidOption)
      expect { handle(format: :jpeg, quality: 0) }.to raise_error(described_class::InvalidOption)
      expect { handle(format: :jpeg, quality: 101) }.to raise_error(described_class::InvalidOption)
    end
  end
end
