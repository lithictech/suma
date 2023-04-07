# frozen_string_literal: true

require "suma/mobility/lime_vendor_adapter"

require "suma/lime"

RSpec.describe Suma::Mobility::LimeVendorAdapter, :db do
  describe "LimeVendorAdapter" do
    let(:lime_vendor_adapter) { Suma::Mobility::LimeVendorAdapter.new }
    let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$15")).create }
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }
    let(:vehicle) { Suma::Fixtures.mobility_vehicle.create(vendor_service:) }
    let(:rate) { Suma::Fixtures.vendor_service_rate.for_service(vendor_service).create }

    it "can start and stop a trip" do
      trip = Suma::Fixtures.mobility_trip.create(
        member:,
        vehicle_id: "TICTM376DA74U",
        began_at: Time.at(1_528_768_782.421),
      )
      email_address = "members+#{member.id}@sumamembers.org"
      req1 = stub_request(:post, "https://fake-lime-api.com/users").
        with(body: {phone_number: member.phone, email_address:, driver_license_verified: false}.to_json).
        to_return(fixture_response("lime/new_user"))

      req2 = stub_request(:post, "https://fake-lime-api.com/trips/start").
        with(
          body: {vehicle_id: "TICTM376DA74U",
                 user_id: "3499c3de-a923-4466-addb-99aee8c55186",
                 location: {
                   type: "Feature",
                   geometry: {type: "Point", coordinates: [trip.begin_lng, trip.begin_lat]},
                   properties: {timestamp: 1_528_768_782_421},
                 },
                 rate_plan_id: "placeholder",}.to_json,
        ).to_return(fixture_response("lime/start_trip"))

      expect(lime_vendor_adapter.begin_trip(trip)).to be_a(described_class::BeginTripResult)
      expect(req1).to have_been_made
      expect(req2).to have_been_made
      expect(trip).to have_attributes(external_trip_id: be_present)

      trip = Suma::Fixtures.mobility_trip.ended.create(ended_at: Time.at(1_528_768_782.900))
      req3 = stub_request(:post, "https://fake-lime-api.com/trips/#{trip.id}/complete").
        with(
          body: {location: {
            type: "Feature",
            geometry: {type: "Point", coordinates: [trip.end_lng, trip.end_lat]},
            properties: {timestamp: 1_528_768_782_900},
          }}.to_json,
        ).to_return(fixture_response("lime/complete_trip"))
      expect(lime_vendor_adapter.end_trip(trip)).to be_a(described_class::EndTripResult)
      expect(req3).to have_been_made
    end
  end
end
