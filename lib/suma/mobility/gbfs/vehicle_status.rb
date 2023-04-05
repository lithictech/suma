# frozen_string_literal: true

class Suma::Mobility::Gbfs::VehicleStatus
  attr_reader :client, :vendor

  def initialize(client:, vendor:)
    @client = client
    @vendor = vendor
  end

  def sync_all
    # We'll need to modify this when we have GBFS vendors that don't use vehicle_types.json
    vehicles = self.client.fetch_vehicle_status.dig("data", "vehicles")
    vehicle_types = self.client.fetch_vehicle_types.dig("data", "vehicle_types")
    total = 0
    self.vendor.services_dataset.mobility.each do |vs|
      total += self.upsert_vehicles(vs, vehicles, vehicle_types)
    end
    return total
  end

  def upsert_vehicles(vendor_status, vehicles, vehicle_types)
    valid_vehicle_types = vehicle_types.select { |vt| vendor_status.satisfies_constraints?(vt) }
    vehicle_types_by_id = valid_vehicle_types.index_by { |vt| vt["vehicle_type_id"] }
    rows = []
    vehicles.each do |vehicle|
      next unless (vehicle_type = vehicle_types_by_id[vehicle["vehicle_type_id"]])
      battery_level = nil
      if (current_range = vehicle["current_range_meters"]) && (max_range = vehicle_type["max_range_meters"])
        battery_level = ((current_range.to_f / max_range) * 100).round
      end
      row = {
        lat: vehicle["lat"],
        lng: vehicle["lon"],
        vehicle_id: vehicle["vehicle_id"],
        vehicle_type: "escooter",
        vendor_service_id: vendor_status.id,
        battery_level:,
      }
      rows << row
    end
    Suma::Mobility::Vehicle.db.transaction do
      Suma::Mobility::Vehicle.where(vendor_service: vendor_status).delete
      Suma::Mobility::Vehicle.dataset.multi_insert(rows)
    end
    return rows.length
  end
end
