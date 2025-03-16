# frozen_string_literal: true

require "suma/mobility/gbfs"
require "suma/mobility/gbfs/fake_client"

RSpec.describe Suma::Mobility::Gbfs::FreeBikeStatus, :db do
  let(:fake_free_bike_status_json) do
    {
      "last_updated" => 1_640_887_163,
      "ttl" => 0,
      "version" => "2.2",
      "data" => {
        "bikes" => [
          {
            "bike_id" => "ghi799",
            "last_reported" => 1_609_866_204,
            "lat" => 12.11,
            "lon" => 56.81,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "abc123",
            "current_range_meters" => 5000.12,
            "rental_uris" => {"web" => "https://foo.bar"},
          },
          {
            "bike_id" => "ghi700",
            "last_reported" => 1_609_866_100,
            "lat" => 12.38,
            "lon" => 56.80,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "def456",
            "current_range_meters" => 6543.0,
          },
        ],
      },
    }
  end
  let(:fake_vehicle_types_json) do
    {
      "last_updated" => 1_609_866_247,
      "ttl" => 0,
      "version" => "2.2",
      "data" => {
        "vehicle_types" => [
          {
            "vehicle_type_id" => "abc123",
            "form_factor" => "scooter",
            "propulsion_type" => "electric",
            "name" => "Example E-scooter V2",
            "max_range_meters" => 12_000.0,
          },
          {
            "vehicle_type_id" => "def456",
            "form_factor" => "bicycle",
            "propulsion_type" => "electric_assist",
            "name" => "Example E-bike V2",
            "max_range_meters" => 12_000.0,
          },
        ],
      },
    }
  end

  describe "gbfs vehicles" do
    let(:vs) { Suma::Fixtures.vendor_service.mobility.create }
    let(:vendor) { vs.vendor }

    def sync_gbfs(**kw)
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_free_bike_status_json:, fake_vehicle_types_json:, **kw)
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
    end

    it "gets and upserts vehicles" do
      to_update = Suma::Fixtures.mobility_vehicle(vendor_service: vs).
        loc(12.34, 56.78).
        escooter.
        create(vehicle_id: "ghi799", battery_level: 0, rental_uris: {"web" => "update.me"})
      Suma::Fixtures.mobility_vehicle(vendor_service: vs).
        escooter.
        create(vehicle_id: "ghi555")
      sync_gbfs
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(
          vehicle_id: to_update.vehicle_id,
          lat: 12.11,
          lng: 56.81,
          vendor_service: be === vs,
          vehicle_type: "escooter",
          battery_level: 42,
          rental_uris: {"web" => "https://foo.bar"},
        ),
        have_attributes(
          vehicle_id: "ghi700",
          lat: 12.38,
          lng: 56.80,
          vendor_service: be === vs,
          vehicle_type: "ebike",
          battery_level: 55,
          rental_uris: {},
        ),
      )
    end

    it "limits vehicles to those matching the vendor service constraint" do
      vs.update(constraints: [{"form_factor" => "scooter"}, "propulsion_type" => "electric"])

      sync_gbfs
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "ghi799"),
      )
    end

    it "calculates battery level within a valid range" do
      # Set max_range_meters to something lower than bikes current_range_meters
      fake_vehicle_types_json["data"]["vehicle_types"].each { |vt| vt["max_range_meters"] = 2000 }

      sync_gbfs
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "ghi799", battery_level: 100),
        have_attributes(vehicle_id: "ghi700", battery_level: 100),
      )
    end

    it "uses a nil battery level if range is not defined" do
      fake_vehicle_types_json["data"]["vehicle_types"].each { |vt| vt.delete("max_range_meters") }

      sync_gbfs
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "ghi799", battery_level: nil),
        have_attributes(vehicle_id: "ghi700", battery_level: nil),
      )
    end

    it "creates vehicles from stations" do
      fake_station_information_json = {
        "last_updated" => 1_742_061_563,
        "ttl" => 60,
        "version" => "2.3",
        "data" => {
          "stations" => [
            {
              "lat" => 45.53434532,
              "address" => "123 Main St",
              "capacity" => 5,
              "lon" => -122.6848841,
              "station_id" => "station1",
              "name" => "Main 567",
              "rental_uris" => {
                "ios" => "https://pdx.lft.to/lastmile_qr_scan",
                "android" => "https://pdx.lft.to/lastmile_qr_scan",
              },
            },
            {
              "lat" => 45.5604984,
              "address" => "456 Main st",
              "capacity" => 3,
              "lon" => -122.6621038,
              "station_id" => "station2",
              "name" => "Main 456",
              "rental_uris" => {
                "ios" => "https://pdx.lft.to/lastmile_qr_scan",
                "android" => "https://pdx.lft.to/lastmile_qr_scan",
              },
            },

          ],
        },
      }
      fake_station_status_json = {
        "data" => {
          "stations" => [
            {
              "is_renting" => 1,
              "is_installed" => 1,
              "is_returning" => 1,
              "last_reported" => 1_721_678_338,
              "station_id" => "station1",
              "vehicle_types_available" => [
                {"vehicle_type_id" => "abc123", "count" => 1},
                {"vehicle_type_id" => "def456", "count" => 2},
              ],
              "num_bikes_available" => 3,
            },
            {
              "is_renting" => 1,
              "is_installed" => 1,
              "is_returning" => 1,
              "last_reported" => 1_721_678_249,
              "station_id" => "station2",
              "vehicle_types_available" => [
                {"vehicle_type_id" => "abc123", "count" => 1},
                {"vehicle_type_id" => "def456", "count" => 2},
              ],
              "num_bikes_available" => 3,
            },
            {
              "is_renting" => 0,
              "is_installed" => 1,
              "is_returning" => 1,
              "last_reported" => 1_721_678_249,
              "num_ebikes_available" => 4,
              "station_id" => "not_renting",
              "vehicle_types_available" => [
                {"vehicle_type_id" => "abc123", "count" => 10},
                {"vehicle_type_id" => "def456", "count" => 10},
              ],
              "num_bikes_available" => 20,
            },
          ],
        },
        "last_updated" => 1_742_061_744,
        "ttl" => 60,
        "version" => "2.3",
      }
      fake_free_bike_status_json["data"]["bikes"].clear
      sync_gbfs(fake_station_information_json:, fake_station_status_json:)
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(
          lat_int: 455_604_984,
          lng_int: -1_226_621_038,
          vehicle_type: "escooter",
          vehicle_id: "station2-abc123-0",

          rental_uris: {"ios" => "https://pdx.lft.to/lastmile_qr_scan", "android" => "https://pdx.lft.to/lastmile_qr_scan"},
        ),
        have_attributes(vehicle_type: "escooter", vehicle_id: "station1-abc123-0"),
        have_attributes(vehicle_type: "ebike", vehicle_id: "station1-def456-1"),
        have_attributes(vehicle_type: "ebike", vehicle_id: "station2-def456-0"),
        have_attributes(vehicle_type: "ebike", vehicle_id: "station2-def456-1"),
        have_attributes(vehicle_type: "ebike", vehicle_id: "station1-def456-0"),
      )
    end
  end

  describe "derive_vehicle_type" do
    it "maps known vehicle types" do
      ebike = {"form_factor" => "bicycle", "propulsion_type" => "electric_assist", "vehicle_type_id" => "2"}
      escooter = {"form_factor" => "scooter", "propulsion_type" => "electric", "vehicle_type_id" => "3"}
      bike = {"form_factor" => "bicycle", "propulsion_type" => "human", "vehicle_type_id" => "1"}
      expect(described_class.derive_vehicle_type(ebike)).to eq(Suma::Mobility::EBIKE)
      expect(described_class.derive_vehicle_type(escooter)).to eq(Suma::Mobility::ESCOOTER)
      expect(described_class.derive_vehicle_type(bike)).to eq(Suma::Mobility::BIKE)
    end

    it "raises an error for unhandled vehicle types" do
      vt = {"form_factor" => "cart", "propulsion_type" => "feet", "vehicle_type_id" => "3"}
      expect { described_class.derive_vehicle_type(vt) }.to raise_error(Suma::Mobility::UnknownVehicleType)
    end
  end
end
