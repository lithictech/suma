# frozen_string_literal: true

module Suma::Mobility
  class OutOfBounds < ArgumentError; end

  # How far do we multiply a normal float coordinate (lat or lng)
  # to get an integer coordinate?
  COORD2INT_FACTOR = 10_000_000
  # Convert an integer coordinate back to a float.
  INT2COORD_FACTOR = BigDecimal("1") / COORD2INT_FACTOR
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

  # Same location vehicles are spread equally around that location in a circular manner.
  # We pass an offset variable for each vehicle to evaluate their new position.
  def self.offset_disambiguated_vehicles(map_obj:)
    map_obj.each_value do |vehicles|
      vehicles.group_by { |v| v[:c] }.each do |_, shared_loc_vehicles|
        next if shared_loc_vehicles.count <= 1
        two_pi = Math::PI * 2
        circle_circumference = 50 * shared_loc_vehicles.count
        spread_length = circle_circumference / two_pi
        angle_step = two_pi / shared_loc_vehicles.count
        shared_loc_vehicles.each_with_index do |v, idx|
          angle = angle_step * idx
          lat, lng = v[:c]
          offset_lat = (lat + (spread_length * Math.cos(angle))).round
          offset_lng = (lng + (spread_length * Math.sin(angle))).round
          v[:o] = [offset_lat, offset_lng]
        end
      end
    end
  end
end
