# frozen_string_literal: true

require "appydays/configurable"
require "geokit"
require "appydays/loggable"

require "suma/postgres/model"

class Suma::MobilityVehicle < Suma::Postgres::Model(:mobility_vehicles)
  class OutOfBounds < ArgumentError; end

  plugin :timestamps

  many_to_one :platform_partner, key: :platform_partner_id, class: "Suma::PlatformPartner"

  dataset_module do
    def search(min_lat:, min_lng:, max_lat:, max_lng:)
      return self.where { (lat >= min_lat) & (lat <= max_lat) & (lng >= min_lng) & (lng <= max_lng) }
    end
  end

  # How far do we multiply a normal float coordinate (lat or lng)
  # to get an integer coordinate?
  COORD2INT_FACTOR = 10_000_000
  # Convert an integer coordinate back to a float.
  INT2COORD_FACTOR = 1.0 / COORD2INT_FACTOR
  COORD_RANGE = -180.0..180.0
  INTCOORD_RANGE = (-180.0 * COORD2INT_FACTOR)..(180.0 * COORD2INT_FACTOR)

  def self.coord2int(c)
    raise OutOfBounds, "#{c} must be between -180 and 180" unless COORD_RANGE.cover?(c)
    return (c * COORD2INT_FACTOR).to_i
  end

  def self.int2coord(i)
    raise OutOfBounds, "#{i} must be between -1.8b and 1.8b" unless INTCOORD_RANGE.cover?(i)
    return i * INT2COORD_FACTOR
  end

  def api_identity
    return "#{self.lat}-#{self.lng}-#{self.platform_partner_id}-#{self.vehicle_type}"
  end

  def to_api_location
    return [self.class.coord2int(self.lat), self.class.coord2int(self.lng)]
  end
end
