# frozen_string_literal: true

require "suma/mobility/gbfs"
require "suma/mobility/gbfs/fake_client"

RSpec.describe Suma::Mobility::Gbfs::GeofencingZone, :db do
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }
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

  describe "GBFS geofencing" do
    it "gets and upserts geofencing zones" do
      z = described_class.new(client:, vendor: vendor_service.vendor)
      z.sync_all
      expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
        have_attributes(
          title: "NE 24th/NE Knott",
          unique_id: "NE 24th/NE Knott",
        ),
      )
    end

    it "limits zones to those matching the vendor service constraint" do
      vs = vendor_service.update(constraints: [{"form_factor" => "scooter"}, "propulsion_type" => "electric"])
      z = described_class.new(client:, vendor: vs.vendor)
      z.sync_all
      expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
        have_attributes(
          title: "NE 24th/NE Knott",
          unique_id: "NE 24th/NE Knott",
        ),
      )
    end
  end

  it "sets correct zone restriction based on rules" do
    vs = vendor_service.update(constraints: [{"form_factor" => "scooter"}, "propulsion_type" => "electric"])
    z = described_class.new(client:, vendor: vs.vendor)
    z.sync_all
    expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
      have_attributes(restriction: "do-not-park"),
    )
  end
end
