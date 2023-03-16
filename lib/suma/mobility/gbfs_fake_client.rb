# frozen_string_literal: true

class Suma::Mobility::GbfsFakeClient
  attr_reader :fake_geofencing_json

  def initialize(fake_geofencing_json: nil)
    @fake_geofencing_json = fake_geofencing_json
  end

  def fetch_geofencing_zones
    @fake_geofencing_json
  end
end
