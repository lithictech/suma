# frozen_string_literal: true

class Suma::Mobility::Gbfs::GeofencingZone
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def sync_all
    fetched = self.client.fetch_geofencing_zones
    fetched["data"]["geofencing_zones"]["features"].each do |f|
      coords = f["geometry"]["coordinates"].each do |polyline|
        polyline.each do |lng_lat|
          lng_lat.each(&:reverse!)
        end
      end
      unique_id = f["properties"]["name"]
      Suma::Mobility::RestrictedArea.find_or_create(unique_id:, title: unique_id) do |ra|
        ra.multipolygon = coords
      end
    end
  end
end
