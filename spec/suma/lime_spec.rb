# frozen_string_literal: true

require "suma/lime"

RSpec.describe Suma::Lime, :db do
  describe "start_trip" do
    it "begin a trip successfully" do
      timestamp = Time.now
      req = stub_request(:post, "https://fake-lime-api.com/trips/start").
        with(
          headers: {"Authorization" => "Bearer get-from-lime-add-to-env"},
          body: {vehicle_id: "TICTM376DA74U",
                 user_id: "d01ffe12-8d72-4ea2-928f-899774caed2f",
                 location: {
                   type: "Feature",
                   geometry: {
                     type: "Point",
                     coordinates: [
                       122.4194,
                       37.7749,
                     ],
                   },
                   properties: {
                     timestamp:,
                   },
                 },
                 rate_plan_id: "d01ffe12-8d72-4ea2-928f-899774caed2f",}.to_json,
        ).to_return(fixture_response("lime/start_trip"))

      resp = described_class.start_trip(
        vehicle_id: "TICTM376DA74U",
        user_id: "d01ffe12-8d72-4ea2-928f-899774caed2f",
        lat: 37.7749, lng: 122.4194, rate_plan_id: "d01ffe12-8d72-4ea2-928f-899774caed2f",
        timestamp:,
      )
      expect(req).to have_been_made
      expect(resp).to include("data" => hash_including(
        "id" => "fa03adb1-7755-429f-a80f-ad6836a960ee",
        "status" => "started",
      ))
    end
  end
end
