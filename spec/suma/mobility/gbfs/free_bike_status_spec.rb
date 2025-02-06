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

    def sync_gbfs
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_free_bike_status_json:, fake_vehicle_types_json:)
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
