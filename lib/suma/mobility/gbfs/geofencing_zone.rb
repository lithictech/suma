# frozen_string_literal: true

class Suma::Mobility::Gbfs::GeofencingZone
  attr_reader :client, :vendor

  def initialize(client:, vendor:)
    @client = client
    @vendor = vendor
  end

  def sync_all
    zones = self.client.fetch_geofencing_zones.dig("data", "geofencing_zones")
    vehicle_types = self.client.fetch_vehicle_types.dig("data", "vehicle_types")
    self.vendor.services_dataset.mobility.each do |vs|
      self.upsert_geofencing_zones(vs, zones, vehicle_types)
    end
  end

  def upsert_geofencing_zones(vendor_status, zones, vehicle_types)
    valid_vehicle_types = vehicle_types.select { |vt| vendor_status.satisfies_constraints?(vt) }
    vehicle_types_by_id = valid_vehicle_types.index_by { |vt| vt["vehicle_type_id"] }
    zones["features"].each do |f|
      restriction = ""
      if (rule = f["properties"]["rules"].first)
        has_valid_id = false
        rule["vehicle_type_id"].each do |id|
          has_valid_id = vehicle_types_by_id.key?(id)
        end
        next unless has_valid_id
        restriction = "do-not-park" if rule["ride_allowed"] == false
        restriction = "do-not-ride" if rule["ride_through_allowed"] == false
        restriction = "do-not-park-or-ride" if rule["ride_through_allowed"] == false && rule["ride_allowed"] == false
      end

      coords = f["geometry"]["coordinates"].each do |polyline|
        polyline.each do |lng_lat|
          lng_lat.each(&:reverse!)
        end
      end
      # when no property name found, we use first coords to identify zone
      unique_id = f["properties"]["name"] || "#{coords.flatten[0]}/#{coords.flatten[1]}"
      Suma::Mobility::RestrictedArea.find_or_create(unique_id:, title: unique_id) do |ra|
        ra.restriction = restriction unless restriction.empty?
        ra.multipolygon = coords
      end
    end
  end
end
