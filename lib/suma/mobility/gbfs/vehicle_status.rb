# frozen_string_literal: true

class Suma::Mobility::Gbfs::VehicleStatus
  attr_reader :client, :vendor_slug

  def initialize(client:, vendor_slug:)
    @client = client
    @vendor_slug = vendor_slug
  end

  def sync_all
    (v = Suma::Vendor[slug: self.vendor_slug]) or
      raise Suma::InvalidPrecondition, "Suma::Vendor[slug: #{self.vendor_slug}] partner must exist in order to sync"
    services = v.services_dataset.mobility
    total = 0
    services.each do |vs|
      raise "Cannot sync unknown mobility url: #{vs.inspect}" unless vs.sync_url.include?("/v2/gbfs_transit/")
      total += self.upsert_all(vs)
    end
    return total
  end

  def upsert_all(vs)
    resp = self.client.fetch_vehicle_status
    resp_types = self.client.fetch_vehicle_types
    valid_types = resp_types["data"]["vehicle_types"].select { |vt| vt["form_factor"].start_with?("scooter") }
    rows = []
    resp["data"]["vehicles"].each do |vehicle|
      next unless (vehicle_type = valid_types.find { |vt| vt["vehicle_type_id"] === vehicle["vehicle_type_id"] })
      battery_level = ((vehicle["current_range_meters"].to_f / vehicle_type["max_range_meters"]) * 100).round
      row = {
        lat: vehicle["lat"],
        lng: vehicle["lon"],
        vehicle_id: vehicle["vehicle_id"],
        vehicle_type: "escooter",
        vendor_service_id: vs.id,
        battery_level:,
      }
      rows << row
    end
    Suma::Mobility::Vehicle.db.transaction do
      Suma::Mobility::Vehicle.where(vendor_service: vs).delete
      Suma::Mobility::Vehicle.dataset.multi_insert(rows)
    end
    return rows.length
  end
end
