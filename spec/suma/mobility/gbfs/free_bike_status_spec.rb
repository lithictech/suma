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
          },
          {
            "bike_id" => "ghi700",
            "last_reported" => 1_609_866_100,
            "lat" => 12.38,
            "lon" => 56.80,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "abc123",
            "current_range_meters" => 6543.0,
          },
          {
            "vehicle_type_id" => "car1",
            "form_factor" => "car",
            "propulsion_type" => "combustion",
            "name" => "Foor-door Sedan",
            "max_range_meters" => 523_992,
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
            "propulsion_type" => "human",
            "name" => "Example E-scooter V2",
            "max_range_meters" => 12_000.0,
          },
        ],
      },
    }
  end

  describe "gbfs vehicles" do
    let(:vs) { Suma::Fixtures.vendor_service.mobility.create }
    let(:vendor) { vs.vendor }

    it "gets and upserts vehicles" do
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_free_bike_status_json:, fake_vehicle_types_json:)
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(
          vehicle_id: "ghi799",
          vendor_service: be === vs,
          battery_level: 42,
        ),
        have_attributes(
          vehicle_id: "ghi700",
          vendor_service: be === vs,
          battery_level: 55,
        ),
      )
    end

    it "limits vehicles to those matching the vendor service constraint" do
      vs.update(constraints: [{"form_factor" => "scooter"}, "propulsion_type" => "electric"])
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_free_bike_status_json:, fake_vehicle_types_json:)
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "ghi799"),
        have_attributes(vehicle_id: "ghi700"),
      )
    end

    it "uses a nil battery level if range is not defined" do
      fake_vehicle_types_json["data"]["vehicle_types"].each { |vt| vt.delete("max_range_meters") }
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_free_bike_status_json:, fake_vehicle_types_json:)
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "ghi799", battery_level: nil),
        have_attributes(vehicle_id: "ghi700", battery_level: nil),
      )
    end
  end
end
