# frozen_string_literal: true

class Suma::Mobility::Gbfs::FreeBikeStatus
  attr_reader :client, :vendor

  def initialize(client:)
    @client = client
  end

  def sync_all(vendor_services)
    bikes = self.client.fetch_free_bike_status.dig("data", "bikes")
    vehicle_types = self.client.fetch_vehicle_types.dig("data", "vehicle_types")
    total = 0
    vendor_services.each do |vs|
      total += self.upsert_free_bike_status(vs, bikes, vehicle_types)
    end
    return total
  end

  def upsert_free_bike_status(vendor_service, bikes, vehicle_types)
    valid_vehicle_types = vehicle_types.select { |vt| vendor_service.satisfies_constraints?(vt) }
    vehicle_types_by_id = valid_vehicle_types.index_by { |vt| vt["vehicle_type_id"] }
    rows = []
    bikes.each do |bike|
      next unless (vehicle_type = vehicle_types_by_id[bike["vehicle_type_id"]])
      battery_level = nil
      if (current_range = bike["current_range_meters"]) && (max_range = vehicle_type["max_range_meters"])
        battery_level = ((current_range.to_f / max_range) * 100).round
      end
      row = {
        lat: bike["lat"],
        lng: bike["lon"],
        vehicle_id: bike["bike_id"],
        vehicle_type: "escooter",
        vendor_service_id: vendor_service.id,
        battery_level:,
      }
      rows << row
    end
    Suma::Mobility::Vehicle.db.transaction do
      Suma::Mobility::Vehicle.where(vendor_service:).delete
      Suma::Mobility::Vehicle.dataset.multi_insert(rows)
    end
    return rows.length
  end
end
