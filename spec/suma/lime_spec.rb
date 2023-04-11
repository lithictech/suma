# frozen_string_literal: true

require "suma/lime"

RSpec.describe Suma::Lime, :db do
  describe "API wrappers" do
    it "begins a trip" do
      req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/start").
        with(
          headers: {"Authorization" => "Bearer get-from-lime-add-to-env"},
          body: {vehicle_id: "TICTM376DA74U",
                 user_id: "d01ffe12-8d72-4ea2-928f-899774caed2f",
                 location: {
                   type: "Feature",
                   geometry: {type: "Point", coordinates: [122.4194, 37.7749]},
                   properties: {timestamp: 1_528_768_782_421},
                 },
                 rate_plan_id: "placeholder",}.to_json,
        ).to_return(fixture_response("lime/start_trip"))

      resp = described_class.start_trip(
        vehicle_id: "TICTM376DA74U",
        user_id: "d01ffe12-8d72-4ea2-928f-899774caed2f",
        lat: 37.7749,
        lng: 122.4194,
        rate_plan_id: "placeholder",
        at: Time.at(1_528_768_782.421),
      )
      expect(req).to have_been_made
      expect(resp).to include("data" => hash_including(
        "id" => "fa03adb1-7755-429f-a80f-ad6836a960ee",
        "status" => "started",
      ))
    end

    it "completes a trip" do
      req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/trips/mytrip/complete").
        with(
          headers: {"Authorization" => "Bearer get-from-lime-add-to-env"},
          body: {
            location: {
              type: "Feature",
              geometry: {type: "Point", coordinates: [122.4194, 37.7749]},
              properties: {timestamp: 1_681_238_802_098},
            },
          }.to_json,
        ).to_return(fixture_response("lime/complete_trip"))

      resp = described_class.complete_trip(
        trip_id: "mytrip",
        lat: 37.7749,
        lng: 122.4194,
        at: Time.at(1_681_238_802.098),
      )
      expect(req).to have_been_made
      expect(resp).to include("data" => hash_including("completed_at" => "2022-01-19T10:17:20:12Z"))
    end

    it "gets trip details" do
      trip_id = "fa03adb1-7755-429f-a80f-ad6836a960ee"
      req = stub_request(:get, "https://external-api.lime.bike/api/maas/v1/partner/trips/#{trip_id}").
        with(headers: {"Authorization" => "Bearer get-from-lime-add-to-env"}).
        to_return(fixture_response("lime/trip"))

      resp = described_class.get_trip(trip_id)
      expect(req).to have_been_made
      expect(resp).to include("id" => trip_id, "status" => "started", "vehicle_id" => "TICTM376DA74U")
    end

    it "gets vehicle details" do
      qr_code_json = {sn: "PAD2V"}
      license_plate = "PAD2V"
      url = "https://external-api.lime.bike/api/maas/v1/partner/vehicle?qr_code=#{qr_code_json}&license_plate=#{license_plate}"
      req = stub_request(:get, url).
        with(headers: {"Authorization" => "Bearer get-from-lime-add-to-env"}).
        to_return(fixture_response("lime/vehicle"))

      resp = described_class.get_vehicle(qr_code_json:, license_plate:)
      expect(req).to have_been_made
      expect(resp).to include("data" => hash_including(
        "id" => "514a597d-127c-4873-abf9-f036912671e1",
        "type" => "vehicles",
      ))
    end

    it "creates a new user successfully" do
      phone_number = "14155555555"
      email_address = "members+123@sumamembers.org"
      driver_license_verified = false
      req = stub_request(:post, "https://external-api.lime.bike/api/maas/v1/partner/users").
        with(
          headers: {"Authorization" => "Bearer get-from-lime-add-to-env"},
          body: {phone_number:, email_address:, driver_license_verified:},
        ).
        to_return(fixture_response("lime/new_user"))

      resp = described_class.create_user(phone_number:, email_address:, driver_license_verified:)
      expect(req).to have_been_made
      expect(resp).to include("data" => hash_including(
        "id" => "3499c3de-a923-4466-addb-99aee8c55186",
        "email_address" => email_address,
        "created_at" => "2021-01-19T10:17:20:12Z",
      ))
    end
  end
end
