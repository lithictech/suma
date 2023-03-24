# frozen_string_literal: true

class Suma::Mobility::GbfsFakeClient
  def initialize(fake_geofencing_json: nil, fake_vehicle_status_json: nil)
    @fake_geofencing_json = fake_geofencing_json
    @fake_vehicle_status_json = fake_vehicle_status_json
  end

  def fetch_geofencing_zones
    @fake_geofencing_json
  end

  def fetch_vehicle_status
    @fake_vehicle_status_json
  end
end
