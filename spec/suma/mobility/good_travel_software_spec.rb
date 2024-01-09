# frozen_string_literal: true

require "suma/mobility/good_travel_software"
require "suma/mobility/gbfs/fake_client"

RSpec.describe Suma::Mobility::GoodTravelSoftware, :db do
  let(:fake_free_bike_status_json) do
    {
      "data" => {
        "bikes" => [
          {
            "bike_id" => "abc-1-2-3",
            "last_reported" => 1_609_866_204,
            "lat" => 12.11,
            "lon" => 56.81,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "abc123",
          },
          {
            "bike_id" => "bca-1-4-5",
            "last_reported" => 1_609_866_100,
            "lat" => 12.38,
            "lon" => 50.50,
            "is_reserved" => false,
            "is_disabled" => false,
            "vehicle_type_id" => "abc123",
          },
        ],
      },
    }
  end
  let(:fake_vehicle_types_json) do
    {
      "data" => {
        "vehicle_types" => [
          {
            "vehicle_type_id" => "abc123",
            "form_factor" => "car",
            "propulsion_type" => "gas",
            "name" => "Compact",
            "max_range_meters" => 99_999,
          },
        ],
      },
    }
  end

  describe "vehicle sync" do
    let(:vs) { Suma::Fixtures.vendor_service.mobility.create }
    let(:vendor) { vs.vendor }

    def sync_gbfs
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_free_bike_status_json:, fake_vehicle_types_json:)
      Suma::Mobility::Gbfs::VendorSync.new(
        client:, vendor:, component: Suma::Mobility::Gbfs::FreeBikeStatus.new,
      ).sync_all
    end

    it "gets and upserts vehicles" do
      sync_gbfs
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(
          vehicle_id: "abc-1-2-3",
          vendor_service: be === vs,
          battery_level: nil,
          rental_uris: {},
        ),
        have_attributes(
          vehicle_id: "bca-1-4-5",
          vendor_service: be === vs,
          battery_level: nil,
          rental_uris: {},
        ),
      )
    end

    it "limits vehicles to those matching the vendor service constraint" do
      vs.update(constraints: [{"form_factor" => "car"}, "propulsion_type" => "electric"])

      sync_gbfs
      expect(Suma::Mobility::Vehicle.all).to contain_exactly(
        have_attributes(vehicle_id: "abc-1-2-3"),
        have_attributes(vehicle_id: "bca-1-4-5"),
      )
    end
  end
end
