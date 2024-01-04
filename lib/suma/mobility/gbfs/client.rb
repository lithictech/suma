# frozen_string_literal: true

# Abstract base class for GBFS clients.
# Each method returns PORO (plain-old-ruby-objects like Hash, Array, etc)
# corresponding to a GBFS endpoint. See files in spec/data/lime
# for example payloads.
class Suma::Mobility::Gbfs::Client
  def fetch_geofencing_zones = raise NotImplementedError
  def fetch_free_bike_status = raise NotImplementedError
  def fetch_vehicle_types = raise NotImplementedError
end
