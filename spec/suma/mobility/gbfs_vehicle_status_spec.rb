# frozen_string_literal: true

require "suma/mobility/gbfs_fake_client"
require "suma/mobility/gbfs_vehicle_status"

RSpec.describe Suma::Mobility::GbfsVehicleStatus, :db do
  let(:fake_vehicle_status_json) do
    {
      "last_updated" => 1_640_887_163,
      "ttl" => 0,
      "version" => "3.0",
      "data" => {
        "vehicles" => [
          {
            "vehicle_id" => "973a5c94-c288-4a2b-afa6-de8aeb6ae2e5",
            "last_reported" => 1_609_866_109,
            "lat" => 12.345678,
            "lon" => 56.789012,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "abc123",
            "rental_uris" => {
              "android" => "https://www.example.com/app?vehicle_id=973a5c94-c288-4a2b-afa6-de8aeb6ae2e5&platform=android&",
              "ios" => "https://www.example.com/app?vehicle_id=973a5c94-c288-4a2b-afa6-de8aeb6ae2e5&platform=ios",
            },
          },
          {
            "vehicle_id" => "973a5c94-c288-4a2b-afa6-de8aeb6ae1e7",
            "last_reported" => 1_609_866_301,
            "lat" => 12.345611,
            "lon" => 56.789001,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "abc234",
            "rental_uris" => {
              "android" => "https://www.example.com/app?vehicle_id=973a5c94-c288-4a2b-afa6-de8aeb6ae1e7&platform=android&",
              "ios" => "https://www.example.com/app?vehicle_id=973a5c94-c288-4a2b-afa6-de8aeb6ae1e7&platform=ios",
            },
          },
        ],
      },
    }
  end

  describe "gbfs vehicles" do
    # TODO: mock stub request
    it "gets and upserts vehicle statuses" do
      client = Suma::Mobility::GbfsFakeClient.new(fake_vehicle_status_json:)
      vendor = Suma::Fixtures.vendor(name: "Lime").create
      vs = Suma::Fixtures.vendor_service(vendor:).mobility
      vs.create(sync_url: "https://data.lime.bike/api/partners/v2/gbfs_transit/vehicle_status.json")

      z = described_class.new(client:)
      z.sync_all(vendor.slug)
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae2e5"),
        have_attributes(vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae1e7"),
      )
    end
  end
end
