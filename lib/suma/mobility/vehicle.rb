# frozen_string_literal: true

require "suma/mobility"
require "suma/postgres/model"

class Suma::Mobility::Vehicle < Suma::Postgres::Model(:mobility_vehicles)
  plugin :timestamps

  many_to_one :vendor_service, key: :vendor_service_id, class: "Suma::Vendor::Service"

  dataset_module do
    def search(min_lat:, min_lng:, max_lat:, max_lng:)
      return self.where { (lat >= min_lat) & (lat <= max_lat) & (lng >= min_lng) & (lng <= max_lng) }
    end
  end

  def api_identity
    return "#{self.lat}-#{self.lng}-#{self.vendor_service_id}-#{self.vehicle_type}"
  end

  def to_api_location
    return [Suma::Mobility.coord2int(self.lat), Suma::Mobility.coord2int(self.lng)]
  end
end
