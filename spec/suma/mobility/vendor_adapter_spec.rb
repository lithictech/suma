# frozen_string_literal: true

require "suma/mobility/vendor_adapter"

RSpec.describe Suma::Mobility::VendorAdapter, :db do
  describe "registry" do
    it "returns a registered adapter" do
      expect(described_class.create(:fake)).to be_a(Suma::Mobility::FakeVendorAdapter)
      expect(described_class.create("fake")).to be_a(Suma::Mobility::FakeVendorAdapter)
    end

    it "raises for an unknown adapter" do
      expect do
        described_class.create(:blah)
      end.to raise_error(described_class::UnknownAdapter)
    end
  end

  describe "FakeVendorAdapter" do
    let(:ad) { Suma::Mobility::FakeVendorAdapter.new }

    it "can start and stop" do
      trip = Suma::Mobility::Trip.new
      expect(ad.begin_trip(trip)).to be_a(described_class::BeginTripResult)
      expect(trip).to have_attributes(external_trip_id: be_present)
      trip = Suma::Fixtures.mobility_trip.ongoing.create
      expect(ad.end_trip(trip)).to be_a(described_class::EndTripResult)
    end

    it "returns the charge based on the rate" do
      rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(20).create
      trip = Suma::Fixtures.mobility_trip.create(began_at: 5.minutes.ago, vendor_service_rate: rate)
      endres = ad.end_trip(trip)
      expect(endres).to have_attributes(
        cost_cents: 200,
        cost_currency: "USD",
        duration_minutes: 5,
      )
    end
  end
end
