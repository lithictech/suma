# frozen_string_literal: true

require "suma/mobility/gbfs"
require "suma/mobility/gbfs/fake_client"

RSpec.describe Suma::Mobility::Gbfs::GeofencingZone, :db do
  let(:fake_geofencing_json) do
    {
      "last_updated" => 1_640_887_163,
      "ttl" => 60,
      "version" => "2.3-RC2",
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
                    "vehicle_type_id" => [
                      "moped1",
                      "car1",
                    ],
                    "ride_allowed" => false,
                    "ride_through_allowed" => true,
                    "maximum_speed_kph" => 10,
                    "station_parking" => true,
                  },
                ],
              },
            },
          ],
        },
      },
    }
  end

  describe "gbfs geofencing" do
    it "gets and upserts geofencing zones" do
      client = Suma::Mobility::Gbfs::FakeClient.new(fake_geofencing_json:)
      z = described_class.new(client:)
      z.sync_all
      expect(Suma::Mobility::RestrictedArea.all).to contain_exactly(
        have_attributes(
          title: "NE 24th/NE Knott",
          unique_id: "NE 24th/NE Knott",
          multipolygon: [
            [
              [
                [
                  45.562982,
                  -122.578067,
                ],
                [
                  45.562741,
                  -122.661838,
                ],
                [
                  45.504542,
                  -122.661151,
                ],
                [
                  45.5046625,
                  -122.578926,
                ],
                [
                  45.562982,
                  -122.578067,
                ],
              ],
            ],
            [
              [
                [
                  45.548197,
                  -122.650680,
                ],
                [
                  45.534731,
                  -122.650852,
                ],
                [
                  45.535212,
                  -122.630939,
                ],
                [
                  45.548197,
                  -122.630424,
                ],
                [
                  45.548197,
                  -122.650680,
                ],
              ],
            ],
          ],
        ),
      )
    end
  end
end
