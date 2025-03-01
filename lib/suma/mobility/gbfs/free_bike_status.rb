# frozen_string_literal: true

require "suma/mobility/gbfs/component_sync"

class Suma::Mobility::Gbfs::FreeBikeStatus < Suma::Mobility::Gbfs::ComponentSync
  def model = Suma::Mobility::Vehicle
  def external_id_column = :vehicle_id

  def before_sync(client)
    @bikes = client.fetch_free_bike_status.dig("data", "bikes")
    @vehicle_types = client.fetch_vehicle_types.dig("data", "vehicle_types")
  end

  def yield_rows(vendor_service)
    bikes = @bikes
    vehicle_types = @vehicle_types
    valid_vehicle_types = vehicle_types.select { |vt| vendor_service.satisfies_constraints?(vt) }
    vehicle_types_by_id = valid_vehicle_types.index_by { |vt| vt["vehicle_type_id"] }
    bikes.each do |bike|
      next unless (vehicle_type = vehicle_types_by_id[bike["vehicle_type_id"]])
      battery_level = nil
      if (current_range = bike["current_range_meters"]) && (max_range = vehicle_type["max_range_meters"])
        battery_level = ((current_range.to_f / max_range) * 100).round.clamp(0, 100)
      end
      row = {
        lat: bike["lat"],
        lng: bike["lon"],
        lat_int: Suma::Mobility.coord2int(bike["lat"]),
        lng_int: Suma::Mobility.coord2int(bike["lon"]),
        vehicle_id: bike["bike_id"],
        vehicle_type: self.class.derive_vehicle_type(vehicle_type).to_s,
        vendor_service_id: vendor_service.id,
        battery_level: Sequel.cast(battery_level, :smallint),
        rental_uris: Sequel.pg_jsonb(bike["rental_uris"] || {}),
      }
      yield row
    end
  end

  def self.derive_vehicle_type(vehicle_type_json)
    ff = vehicle_type_json.fetch("form_factor")
    pt = vehicle_type_json.fetch("propulsion_type")
    return Suma::Mobility::EBIKE if ff == "bicycle" && pt == "electric_assist"
    return Suma::Mobility::ESCOOTER if ff == "scooter" && pt == "electric"
    return Suma::Mobility::BIKE if ff == "bicycle" && pt == "human"
    raise Suma::Mobility::UnknownVehicleType, "Cannot map vehicle type for form_factor #{ff}, propulsion_type: #{pt}"
  end
end
