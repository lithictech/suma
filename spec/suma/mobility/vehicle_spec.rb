# frozen_string_literal: true

RSpec.describe "Suma::Mobility::Vehicle", :db do
  let(:described_class) { Suma::Mobility::Vehicle }

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
end
