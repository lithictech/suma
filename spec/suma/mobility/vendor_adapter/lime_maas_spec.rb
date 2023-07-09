# frozen_string_literal: true

require "suma/lime"

RSpec.describe Suma::Mobility::VendorAdapter::LimeMaas, :db do
  let(:instance) { described_class.new }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }
  let(:vehicle) { Suma::Fixtures.mobility_vehicle.create(vendor_service:) }
  let(:rate) { Suma::Fixtures.vendor_service_rate.for_service(vendor_service).create }
  let(:trip) do
    Suma::Fixtures.mobility_trip.create(
      member:,
      vehicle_id: "TICTM376DA74U",
      began_at: Time.at(1_528_768_782.421),
    )
  end

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
            properties: {timestamp: 1_528_768_782_421},
          },
          rate_plan_id: "placeholder",
        }.to_json,
      ).to_return(fixture_response("lime/start_trip"))

    expect(instance.begin_trip(trip)).to be_a(described_class::BeginTripResult)
    expect(register_user_req).to have_been_made
    expect(start_trip_req).to have_been_made
    expect(trip).to have_attributes(external_trip_id: "fa03adb1-7755-429f-a80f-ad6836a960ee")
    expect(member.refresh).to have_attributes(lime_user_id: "3499c3de-a923-4466-addb-99aee8c55186")
  end

  it "can start a trip for a registered user" do
    start_trip_req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/start").
      to_return(fixture_response("lime/start_trip"))

    member.update(lime_user_id: "limeuser")
    expect(instance.begin_trip(trip)).to be_a(described_class::BeginTripResult)
    expect(start_trip_req).to have_been_made
    expect(trip).to have_attributes(external_trip_id: "fa03adb1-7755-429f-a80f-ad6836a960ee")
  end

  it "can stop an ongoing trip" do
    member.update(lime_user_id: "myuser")
    trip.update(external_trip_id: "mytrip", end_lng: 120.5, end_lat: 45.2, ended_at: Time.at(1_528_768_782.9))

    stop_req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/mytrip/complete").
      with(
        body: {
          location: {
            type: "Feature",
            geometry: {type: "Point", coordinates: [120.5, 45.2]},
            properties: {timestamp: 1_528_768_782_900},
          },
        }.to_json,
      ).to_return(fixture_response("lime/complete_trip"))
    expect(instance.end_trip(trip)).to have_attributes(end_time: match_time("2022-01-19T10:17:20:12Z"))
    expect(stop_req).to have_been_made
  end
end
