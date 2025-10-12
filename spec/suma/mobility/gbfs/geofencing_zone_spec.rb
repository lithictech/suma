# frozen_string_literal: true

require "suma/mobility/gbfs"
require "suma/mobility/gbfs/fake_client"

RSpec.describe Suma::Mobility::Gbfs::GeofencingZone, :db do
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }
  let(:vendor) { vendor_service.vendor }
  let(:fake_geofencing_json) do
    {
      "last_updated" => 1_604_198_100,
      "ttl" => 60,
      "version" => "2.2",
      "data" => {
        "geofencing_zones" => {
          "type" => "FeatureCollection",
          "features" => [
            {
              "type" => "Feature",
              "geometry" => {
                "type" => "MultiPolygon",
                "coordinates" => [
                  [
                    [
                      [
                        -122.578067,
                        45.562982,
                      ],
                      [
                        -122.661838,
                        45.562741,
                      ],
                      [
                        -122.661151,
                        45.504542,
                      ],
                      [
                        -122.578926,
                        45.5046625,
                      ],
                      [
                        -122.578067,
                        45.562982,
                      ],
                    ],
                  ],
                  [
                    [
                      [
                        -122.650680,
                        45.548197,
                      ],
                      [
                        -122.650852,
                        45.534731,
                      ],
                      [
                        -122.630939,
                        45.535212,
                      ],
                      [
                        -122.630424,
                        45.548197,
                      ],
                      [
                        -122.650680,
                        45.548197,
                      ],
                    ],
                  ],
                ],
              },
              "properties" => {
                "name" => "NE 24th/NE Knott",
                "start" => 1_593_878_400,
                "end" => 1_593_907_260,
                "rules" => [
                  {
                    "vehicle_type_id" => ["abc123"],
                    "ride_allowed" => false,
                    "ride_through_allowed" => true,
                    "maximum_speed_kph" => 10,
                  },
                ],
              },
            },
            {
              "type" => "Feature",
              "geometry" => {
                "type" => "MultiPolygon",
                "coordinates" => [
                  [
                    [
                      [
                        -122.578067,
                        45.562982,
                      ],
                      [
                        -122.661838,
                        45.562741,
                      ],
                      [
                        -122.661151,
                        45.504542,
                      ],
                      [
                        -122.578926,
                        45.5046625,
                      ],
                      [
                        -122.578067,
                        45.562982,
                      ],
                    ],
                  ],
                ],
              },
              "properties" => {
                "name" => "NW 25th/NW NotReal",
                "start" => 1_593_878_400,
                "end" => 1_593_907_260,
                "rules" => [
                  {
                    "vehicle_type_id" => ["abc234"],
                    "ride_allowed" => false,
                    "ride_through_allowed" => true,
                    "maximum_speed_kph" => 10,
                  },
                ],
              },
            },
          ],
        },
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
            "max_range_meters" => 12_345,
          },
          {
            "vehicle_type_id" => "car234",
            "form_factor" => "car",
            "propulsion_type" => "combustion",
            "name" => "Example E-scooter V2",
            "max_range_meters" => 12_345,
          },
        ],
      },
    }
  end
  let(:client) { Suma::Mobility::Gbfs::FakeClient.new(fake_geofencing_json:, fake_vehicle_types_json:) }

  it "gets and upserts geofencing zones" do
    Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
    expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
      have_attributes(
        title: "NE 24th/NE Knott",
        unique_id: "NE 24th/NE Knott",
        restriction: "do-not-park",
      ),
    )
  end

  it "uses all vehicle type ids if none are in the rules" do
    fake_geofencing_json["data"]["geofencing_zones"]["features"][0]["properties"]["rules"][0].delete "vehicle_type_id"
    Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
    expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
      have_attributes(
        title: "NE 24th/NE Knott",
        unique_id: "NE 24th/NE Knott",
        restriction: "do-not-park",
      ),
    )
  end

  it "limits zones to those matching the vendor service constraint" do
    vendor_service.update(constraints: [{"form_factor" => "scooter"}, "propulsion_type" => "electric"])
    Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
    expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
      have_attributes(
        title: "NE 24th/NE Knott",
        unique_id: "NE 24th/NE Knott",
        restriction: "do-not-park",
      ),
    )
  end

  describe "restriction calculation" do
    before(:each) do
      fake_geofencing_json["data"]["geofencing_zones"]["features"].pop
      @rule = fake_geofencing_json["data"]["geofencing_zones"]["features"][0]["properties"]["rules"][0]
    end

    it "uses do-not-ride if ride_through_allowed=false/ride_allowed=true" do
      @rule["ride_through_allowed"] = false
      @rule["ride_allowed"] = true
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
        have_attributes(restriction: "do-not-ride"),
      )
    end

    it "uses do-not-park if ride_through_allowed=true/ride_allowed=false" do
      @rule["ride_through_allowed"] = true
      @rule["ride_allowed"] = false
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
        have_attributes(restriction: "do-not-park"),
      )
    end

    it "uses do-not-park-or-ride if ride_through_allowed=false/ride_allowed=false" do
      @rule["ride_through_allowed"] = false
      @rule["ride_allowed"] = false
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
        have_attributes(restriction: "do-not-park-or-ride"),
      )
    end

    it "uses no restriction if ride_through_allowed=true/ride_allowed=true" do
      @rule["ride_through_allowed"] = true
      @rule["ride_allowed"] = true
      Suma::Mobility::Gbfs::VendorSync.new(client:, vendor:, component: described_class.new).sync_all
      expect(Suma::Mobility::RestrictedArea.all).to be_empty
    end
  end
end
