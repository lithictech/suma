# frozen_string_literal: true

RSpec.describe "Suma::Mobility" do
  let(:described_class) { Suma::Mobility }

  describe "coord2int" do
    it "can convert floating point coords into integers" do
      expect(described_class.coord2int(-179.5)).to eq(-1_795_000_000)
      expect(described_class.coord2int(179.5)).to eq(1_795_000_000)
      expect(described_class.coord2int(5.5)).to eq(55_000_000)
      expect(described_class.coord2int(0.5)).to eq(5_000_000)
      expect(described_class.coord2int(0.543898383823838293223232454)).to eq(5_438_983)
    end

    it "errors if the coordinates are out of bounds" do
      expect { described_class.coord2int(180.1) }.to raise_error(described_class::OutOfBounds)
      expect { described_class.coord2int(-180.1) }.to raise_error(described_class::OutOfBounds)
    end
  end

  describe "int2coord" do
    it "can convert integers back into floating point coords" do
      expect(described_class.int2coord(-1_795_000_000)).to eq(-179.5)
      expect(described_class.int2coord(1_795_000_000)).to eq(179.5)
      expect(described_class.int2coord(55_000_000)).to eq(5.5)
      expect(described_class.int2coord(5_000_000)).to eq(0.5)
      expect(described_class.int2coord(5_438_983)).to eq(0.5438983)
    end

    it "errors if the coordinates are out of bounds" do
      expect { described_class.int2coord(1_800_000_001) }.to raise_error(described_class::OutOfBounds)
      expect { described_class.int2coord(-1_800_000_001) }.to raise_error(described_class::OutOfBounds)
    end
  end
end
