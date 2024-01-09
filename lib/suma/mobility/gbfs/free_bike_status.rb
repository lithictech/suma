# frozen_string_literal: true

require "suma/mobility/gbfs/component_sync"

class Suma::Mobility::Gbfs::FreeBikeStatus < Suma::Mobility::Gbfs::ComponentSync
  def model = Suma::Mobility::Vehicle

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
        vehicle_id: bike["bike_id"],
        vehicle_type: vehicle_type["vehicle_type_id"].start_with?("gts") ? "ecar" : "escooter",
        vendor_service_id: vendor_service.id,
        battery_level:,
        rental_uris: Sequel.pg_jsonb(bike["rental_uris"] || {}),
      }
      yield row
    end
  end

  def _to_suma_vehicle_type(bike, vehicle_type); end
end
