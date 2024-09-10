# frozen_string_literal: true

require "suma/mobility/gbfs/component_sync"

class Suma::Mobility::Gbfs::GeofencingZone < Suma::Mobility::Gbfs::ComponentSync
  def model = Suma::Mobility::RestrictedArea
  def external_id_column = :unique_id

  def before_sync(client)
    @zones = client.fetch_geofencing_zones.dig("data", "geofencing_zones")
    @vehicle_types = client.fetch_vehicle_types.dig("data", "vehicle_types")
  end

  def yield_rows(vendor_service)
    zones = @zones
    vehicle_types = @vehicle_types
    valid_vehicle_types = vehicle_types.select { |vt| vendor_service.satisfies_constraints?(vt) }
    vehicle_types_by_id = valid_vehicle_types.index_by { |vt| vt["vehicle_type_id"] }
    zones["features"].each do |f|
      restriction = ""
      if (rule = f["properties"]["rules"].first)
        rule_vehicle_type_ids = rule["vehicle_type_id"]
        has_valid_id = rule_vehicle_type_ids.blank? || rule_vehicle_type_ids.any? { |id| vehicle_types_by_id.key?(id) }
        next unless has_valid_id
        restriction = if rule["ride_through_allowed"] == false && rule["ride_allowed"] == false
                        "do-not-park-or-ride"
        elsif rule["ride_allowed"] == false
          "do-not-park"
        elsif rule["ride_through_allowed"] == false
          "do-not-ride"
        end
      end
      # We are syncing restricted areas from geofencing zones, but not all geofencing zones
      # indicate restricted areas. For example some are just speed limit zones.
      # See https://github.com/MobilityData/gbfs/blob/master/gbfs.md#geofencing-rule-object
      # for rules.
      # If we can't calculate one of our restrictions, ignore the zone.
      next if restriction.nil?

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
        restriction:,
      )
      row.before_save
      yield row.values
    end
  end
end
