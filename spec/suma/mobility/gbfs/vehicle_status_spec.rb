# frozen_string_literal: true

require "suma/mobility/gbfs"
require "suma/mobility/gbfs/fake_client"

RSpec.describe Suma::Mobility::Gbfs::VehicleStatus, :db do
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
            "current_range_meters" => 4000.0,
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
            "current_range_meters" => 6543.0,
            "rental_uris" => {
              "android" => "https://www.example.com/app?vehicle_id=973a5c94-c288-4a2b-afa6-de8aeb6ae1e7&platform=android&",
              "ios" => "https://www.example.com/app?vehicle_id=973a5c94-c288-4a2b-afa6-de8aeb6ae1e7&platform=ios",
            },
          },
        ],
      },
    }
  end
  let(:fake_vehicle_types_json) do
    {
      "last_updated" => 1_640_887_163,
      "ttl" => 0,
      "version" => "3.0",
      "data" => {
        "vehicle_types" => [
          {
            "vehicle_type_id" => "abc123",
            "form_factor" => "scooter_standing",
            "propulsion_type" => "electric",
            "name" => [
              {
                "text" => "Example E-scooter V2",
                "language" => "en",
              },
            ],
            "wheel_count" => 2,
            "max_permitted_speed" => 25,
            "rated_power" => 350,
            "default_reserve_time" => 30,
            "max_range_meters" => 11_999,
            "return_constraint" => "free_floating",
            "vehicle_assets" => {
              "icon_url" => "https://www.example.com/assets/icon_escooter.svg",
              "icon_url_dark" => "https://www.example.com/assets/icon_escooter_dark.svg",
              "icon_last_modified" => "2021-06-15",
            },
            "default_pricing_plan_id" => "scooter_plan_1",
          },
          {
            "vehicle_type_id" => "abc234",
            "form_factor" => "scooter_standing",
            "propulsion_type" => "electric",
            "name" => [
              {
                "text" => "Example E-scooter V2",
                "language" => "en",
              },
            ],
            "wheel_count" => 2,
            "max_permitted_speed" => 25,
            "rated_power" => 350,
            "default_reserve_time" => 30,
            "max_range_meters" => 12_000.0,
            "return_constraint" => "free_floating",
            "vehicle_assets" => {
              "icon_url" => "https://www.example.com/assets/icon_escooter.svg",
              "icon_url_dark" => "https://www.example.com/assets/icon_escooter_dark.svg",
              "icon_last_modified" => "2021-06-15",
            },
            "default_pricing_plan_id" => "scooter_plan_1",
          },
        ],
      },
    }
  end

  describe "gbfs vehicles" do
    let(:vs) { Suma::Fixtures.vendor_service.mobility.create }

    it "gets and upserts vehicles" do
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_vehicle_status_json:, fake_vehicle_types_json:)
      z = described_class.new(client:, vendor: vs.vendor)
      z.sync_all
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(
          vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae2e5",
          vendor_service: be === vs,
          battery_level: 33,
        ),
        have_attributes(
          vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae1e7",
          vendor_service: be === vs,
          battery_level: 55,
        ),
      )
    end

    it "limits vehicles to those matching the vendor service constraint" do
      vs.update(constraints: [{"max_range_meters" => 12_000.0}])
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_vehicle_status_json:, fake_vehicle_types_json:)
      described_class.new(client:, vendor: vs.vendor).sync_all
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae1e7"),
      )
    end

    it "uses a nil battery level if range is not defined" do
      fake_vehicle_types_json["data"]["vehicle_types"].each { |vt| vt.delete("max_range_meters") }
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_vehicle_status_json:, fake_vehicle_types_json:)
      described_class.new(client:, vendor: vs.vendor).sync_all
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae2e5", battery_level: nil),
        have_attributes(vehicle_id: "973a5c94-c288-4a2b-afa6-de8aeb6ae1e7", battery_level: nil),
      )
    end
  end
end
