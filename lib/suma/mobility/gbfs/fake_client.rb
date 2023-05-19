# frozen_string_literal: true

require "suma/mobility/gbfs/client"

class Suma::Mobility::Gbfs::FakeClient < Suma::Mobility::Gbfs::Client
  def initialize(fake_geofencing_json: nil, fake_free_bike_status_json: nil, fake_vehicle_types_json: nil)
    super()
    @fake_geofencing_json = fake_geofencing_json
    @fake_free_bike_status_json = fake_free_bike_status_json
    @fake_vehicle_types_json = fake_vehicle_types_json
  end

  def fetch_geofencing_zones = @fake_geofencing_json

  def fetch_free_bike_status = @fake_free_bike_status_json

  def fetch_vehicle_types = @fake_vehicle_types_json
end
