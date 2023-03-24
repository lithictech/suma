# frozen_string_literal: true

class Suma::Mobility::GbfsVehicleStatus
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def sync_all(vendor_slug)
    (v = Suma::Vendor[slug: vendor_slug]) or raise "#{vendor_slug} partner does not exist, cannot run this code"
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
    rows = []
    resp["data"]["vehicles"].each do |vehicle|
      row = {
        lat: vehicle["lat"],
        lng: vehicle["lon"],
        vehicle_id: vehicle["vehicle_id"],
        vehicle_type: "escooter",
        vendor_service_id: vs.id,
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
