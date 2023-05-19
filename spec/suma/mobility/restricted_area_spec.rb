# frozen_string_literal: true

RSpec.describe "Suma::Mobility::RestrictedArea", :db do
  let(:described_class) { Suma::Mobility::RestrictedArea }

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_restricted_area.create).to be_a(described_class)
  end

  describe "datasets" do
    describe "intersecting" do
      it "limits result to areas intersecting the given bounds" do
        ra1 = Suma::Fixtures.mobility_restricted_area.diamond(x: 0, y: 0, w: 10, h: 20).create
        ra2 = Suma::Fixtures.mobility_restricted_area.diamond(x: 5, y: 5, w: 10, h: 20).create
        ra3 = Suma::Fixtures.mobility_restricted_area.diamond(x: 10, y: 10, w: 10, h: 20).create

        expect(described_class.intersecting(ne: [-1, -1], sw: [-2, -2]).all).to be_empty
        expect(described_class.intersecting(ne: [1, 1], sw: [0, 0]).all).to have_same_ids_as(ra1)
        expect(described_class.intersecting(ne: [10, 10], sw: [0, 0]).all).to have_same_ids_as(ra1, ra2, ra3)
        expect(described_class.intersecting(ne: [50, 50], sw: [19, 19]).all).to have_same_ids_as(ra3)
      end
    end
  end

  describe "bounds" do
    it "is set on save" do
      expect(
        Suma::Fixtures.mobility_restricted_area.diamond(x: 0, y: 0, w: 10, h: 20).create,
      ).to have_attributes(bounds: {ne: [20, 10], sw: [0, 0]})

      expect(
        Suma::Fixtures.mobility_restricted_area.diamond(x: -100, y: -100, w: 10, h: 20).create,
      ).to have_attributes(bounds: {ne: [-80, -90], sw: [-100, -100]})

      expect(
        Suma::Fixtures.mobility_restricted_area.diamond(x: -5, y: -10, w: 10, h: 20).create,
      ).to have_attributes(bounds: {ne: [10, 5], sw: [-10, -5]})
    end
  end
end
