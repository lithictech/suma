# frozen_string_literal: true

class Suma::Mobility::Gbfs::Client
  def fetch_geofencing_zones = raise NotImplementedError
  def fetch_free_bike_status = raise NotImplementedError
  def fetch_vehicle_types = raise NotImplementedError
  def fetch_station_information = raise NotImplementedError
  def fetch_station_status = raise NotImplementedError
end
