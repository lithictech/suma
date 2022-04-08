# frozen_string_literal: true

RSpec.describe "Suma::MobilityVehicle", :db do
  let(:described_class) { Suma::MobilityVehicle }

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_vehicle.create).to be_a(described_class)
  end

  describe "search" do
    it "can find all vehicles in the given bounds" do
      v1 = Suma::Fixtures.mobility_vehicle.loc(10, 100).create
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).create
      v3 = Suma::Fixtures.mobility_vehicle.loc(30, 130).create
      v4 = Suma::Fixtures.mobility_vehicle.loc(40, 140).create

      results = described_class.search(min_lat: 15, max_lat: 35, min_lng: 115, max_lng: 125)
      expect(results.all).to contain_exactly(v2)
    end
  end

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
