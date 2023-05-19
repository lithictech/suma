# frozen_string_literal: true

class Suma::Mobility::Gbfs::GeofencingZone
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def sync_all(vendor_services)
    zones = self.client.fetch_geofencing_zones.dig("data", "geofencing_zones")
    vehicle_types = self.client.fetch_vehicle_types.dig("data", "vehicle_types")
    total = 0
    vendor_services.each do |vs|
      total += self.upsert_geofencing_zones(vs, zones, vehicle_types)
    end
    return total
  end

  def upsert_geofencing_zones(vendor_service, zones, vehicle_types)
    valid_vehicle_types = vehicle_types.select { |vt| vendor_service.satisfies_constraints?(vt) }
    vehicle_types_by_id = valid_vehicle_types.index_by { |vt| vt["vehicle_type_id"] }
    rows = []
    zones["features"].each do |f|
      restriction = ""
      if (rule = f["properties"]["rules"].first)
        has_valid_id = rule["vehicle_type_id"].any? { |id| vehicle_types_by_id.key?(id) }
        next unless has_valid_id
        restriction = if rule["ride_through_allowed"] == false && rule["ride_allowed"] == false
                        "do-not-park-or-ride"
        elsif rule["ride_allowed"] == false
          "do-not-park"
          elsif rule["ride_through_allowed"] == false
            "do-not-ride"
        end
      end

      f["geometry"]["coordinates"].each do |polyline|
        polyline.each do |lng_lat|
          lng_lat.each(&:reverse!)
        end
      end
      # when no property name found, we use first coords to identify zone
      coords = f["geometry"]["coordinates"]
      unique_id = f["properties"]["name"] || "#{coords.flatten[0]}/#{coords.flatten[1]}"
      row = Suma::Mobility::RestrictedArea.new(
        unique_id:,
        title: unique_id,
        vendor_service:,
        multipolygon: coords,
      )
      row.restriction = restriction if restriction.present?
      row.before_save
      rows << row.values
    end
    Suma::Mobility::Vehicle.db.transaction do
      Suma::Mobility::RestrictedArea.where(vendor_service:).delete
      Suma::Mobility::RestrictedArea.dataset.multi_insert(rows)
    end
    return rows.length
  end
end
