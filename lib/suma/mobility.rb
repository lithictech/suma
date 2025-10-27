# frozen_string_literal: true

module Suma::Mobility
  class OutOfBounds < ArgumentError; end

  # How far do we multiply a normal float coordinate (lat or lng)
  # to get an integer coordinate?
  COORD2INT_FACTOR = 10_000_000
  # Convert an integer coordinate back to a float.
  INT2COORD_FACTOR = BigDecimal(1) / COORD2INT_FACTOR
  COORD_RANGE = -180.0..180.0
  INTCOORD_RANGE = (-180.0 * COORD2INT_FACTOR)..(180.0 * COORD2INT_FACTOR)
  # This 'magnitude' is in lat/lng degrees/minutes. It is not an actual
  # distance like in meters (it isn't worth the complexity).
  # 0.0000080 degrees is about 1 meter.
  SPIDERIFY_OFFSET_MAGNITUDE = 0.000016

  EBIKE = :ebike
  ESCOOTER = :escooter
  BIKE = :bike
  VEHICLE_TYPES = [EBIKE, ESCOOTER, BIKE].freeze
  VEHICLE_TYPE_STRINGS = VEHICLE_TYPES.map(&:to_s)

  class UnknownVehicleType < ArgumentError; end

  class BeginTripResult < Suma::TypedStruct
  end

  class EndTripResult < Suma::TypedStruct
    class LineItem < Suma::TypedStruct
      # @return [String]
      attr_reader :memo

      # @return [Money]
      attr_reader :amount
    end

    # The cost of the trip without discounts.
    # @return [Money]
    attr_reader :undiscounted_cost

    # Line items for components of the trip, including unlock fee, trip cost, parking violations, etc.
    # @return [Array<LineItem>]
    attr_reader :line_items

    # If a charge was made off-platform (usually through a deeplink vendor),
    # record it here so we record it properly and do not try to charge the balance.
    attr_reader :charged_off_platform
  end

  def self.coord2int(c)
    raise OutOfBounds, "#{c} must be between -180 and 180" unless COORD_RANGE.cover?(c)
    return (c * COORD2INT_FACTOR).to_i
  end

  def self.int2coord(i)
    raise OutOfBounds, "#{i} must be between -1.8b and 1.8b" unless INTCOORD_RANGE.cover?(i)
    return i * INT2COORD_FACTOR
  end

  # *map_vehicles* is a hash, where the key is the type of vehicle (:ebike, :escooter)
  # and the values is an array of hashes describing an individual vehicle.
  #
  # Each vehicle hash contains a :c key which is a tuple
  # of "integer" lat and lng. For example [{c:[45_000_000,-120_000_000]}].
  #
  # Any vehicles (across types) that occupy the same coordinates must be offset
  # so they are not at the same point on the map.
  #
  # The vehicle hash for these vehicles gets modified to contain an :o key,
  # which contains a value of the "integer" lat and lng offset.
  # For example, a vehicle hash at the same coordinates as another vehicle
  # would be modified to {c:[45_000_000,-120_000_000], o:[60, 60]}.
  def self.offset_disambiguated_vehicles(map_vehicles)
    all_vehicles = map_vehicles.values.flatten
    all_vehicles.group_by { |v| v[:c] }.each_value do |shared_loc_vehicles|
      next if shared_loc_vehicles.count <= 1
      # For each vehicle occupying the same point,
      # we want to offset each one around a circle, equidistant from
      # the others on the circumference of the circle.
      # Note that we talk about a circle here,
      # but since lat and lng do not form a square grid,
      # the circle is effectively an oval (more severe towards global poles).
      # This is fine though since the circle is so small, no one will know.
      unit_circle_circumference = 2 * Math::PI # C = 2 * PI * R, R = 1 here
      angle_step = unit_circle_circumference / shared_loc_vehicles.count
      # This 'magnitude' is in lat/lng degrees/minutes. It is not an actual
      # distance like in meters (it isn't worth the complexity).
      # 0.0000080 degrees is about 1 meter.
      offset_magnitude = Suma::Mobility::SPIDERIFY_OFFSET_MAGNITUDE * COORD2INT_FACTOR
      shared_loc_vehicles.each_with_index do |v, idx|
        angle = angle_step * idx
        # The first step is 'up' and we want to avoid scooters vertically stacked
        angle += angle_step * 0.5
        offset_lat = (offset_magnitude * Math.cos(angle)).round
        offset_lng = (offset_magnitude * Math.sin(angle)).round
        v[:o] = [offset_lat, offset_lng]
      end
    end
  end
end
