# frozen_string_literal: true

require "suma/mobility/behaviors"
require "suma/mobility/trip_provider"

RSpec.describe Suma::Mobility::TripProvider::LimeMaas, :db do
  let(:instance) { described_class.new }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }
  let(:vehicle) { Suma::Fixtures.mobility_vehicle.create(vendor_service:) }
  let(:rate) { Suma::Fixtures.vendor_service_rate.for_service(vendor_service).create }
  let(:trip_started) { Time.parse(load_fixture_data("lime/complete_trip").fetch("data").fetch("started_at")) }
  let(:trip_ended) { Time.parse(load_fixture_data("lime/complete_trip").fetch("data").fetch("completed_at")) }
  let(:trip) do
    Suma::Fixtures.mobility_trip.create(
      member:,
      vehicle_id: "TICTM376DA74U",
      began_at: trip_started,
    )
  end

  it_behaves_like "a mobility trip provider"

  it "registers an unregistered user when starting a trip" do
    register_user_req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/users").
      with(
        body: {
          phone_number: member.phone,
          email_address: "members+#{member.id}@sumamembers.org",
          driver_license_verified: false,
        }.to_json,
      ).to_return(fixture_response("lime/new_user"))

    start_trip_req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/start").
      with(
        body: {
          vehicle_id: "TICTM376DA74U",
          user_id: "3499c3de-a923-4466-addb-99aee8c55186",
          location: {
            type: "Feature",
            geometry: {type: "Point", coordinates: [trip.begin_lng.to_f, trip.begin_lat.to_f]},
            properties: {timestamp: trip_started.to_i * 1000},
          },
          rate_plan_id: "placeholder",
        }.to_json,
      ).to_return(fixture_response("lime/start_trip"))

    expect(instance.begin_trip(trip)).to be_a(Suma::Mobility::BeginTripResult)
    expect(register_user_req).to have_been_made
    expect(start_trip_req).to have_been_made
    expect(trip).to have_attributes(external_trip_id: "fa03adb1-7755-429f-a80f-ad6836a960ee")
    expect(member.refresh).to have_attributes(lime_user_id: "3499c3de-a923-4466-addb-99aee8c55186")
  end

  it "can start a trip for a registered user" do
    start_trip_req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/start").
      to_return(fixture_response("lime/start_trip"))

    member.update(lime_user_id: "limeuser")
    expect(instance.begin_trip(trip)).to be_a(Suma::Mobility::BeginTripResult)
    expect(start_trip_req).to have_been_made
    expect(trip).to have_attributes(external_trip_id: "fa03adb1-7755-429f-a80f-ad6836a960ee")
  end

  it "can stop an ongoing trip" do
    member.update(lime_user_id: "myuser")
    rate = Suma::Fixtures.vendor_service_rate.surcharge(100).discounted_by(0.5).create
    fake_end = Time.parse("2025-09-17T09:43:05Z")
    trip.update(
      vendor_service_rate: rate,
      external_trip_id: "mytrip",
      end_lng: 120.5,
      end_lat: 45.2,
      ended_at: fake_end, # Should be set to actual trip end time
    )

    stop_req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/mytrip/complete").
      with(
        body: {
          location: {
            type: "Feature",
            geometry: {type: "Point", coordinates: [120.5, 45.2]},
            properties: {timestamp: fake_end.to_i * 1000},
          },
        }.to_json,
      ).to_return(fixture_response("lime/complete_trip"))
    expect(instance.end_trip(trip)).to have_attributes(
      undiscounted_cost: cost("$2"),
      line_items: contain_exactly(
        have_attributes(memo: "Unlock fee", amount: cost("$1")),
        have_attributes(memo: "Ride cost (0.00/min for 5 min)", amount: cost("$0")),
      ),
    )
    expect(stop_req).to have_been_made
  end
end
