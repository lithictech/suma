# frozen_string_literal: true

require "suma/mobility/behaviors"
require "suma/mobility/vendor_adapter"

RSpec.describe Suma::Mobility::VendorAdapter::Internal, :db do
  let(:ad) { described_class.new }

  it_behaves_like "a mobility vendor adapter"

  it "does not use deep linking" do
    expect(ad).to_not be_uses_deep_linking
  end

  it "can start and stop" do
    trip = Suma::Mobility::Trip.new
    expect(ad.begin_trip(trip)).to be_a(described_class::BeginTripResult)
    expect(trip).to have_attributes(external_trip_id: be_present)
    trip = Suma::Fixtures.mobility_trip.ended.create
    expect(ad.end_trip(trip)).to be_a(described_class::EndTripResult)
  end

  it "returns the charge based on the rate" do
    rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(20).discounted_by(0.5).create
    t = Time.now
    trip = Suma::Fixtures.mobility_trip.create(began_at: t, vendor_service_rate: rate)
    trip.ended_at = t + 5.minutes
    endres = ad.end_trip(trip)
    expect(endres).to have_attributes(
      cost: cost("$2"),
      undiscounted: cost("$4"),
    )
  end
end
