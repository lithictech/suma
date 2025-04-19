# frozen_string_literal: true

require "suma/mobility"
require "suma/mobility/gbfs"
require "suma/postgres/model"

class Suma::Mobility::GbfsFeed < Suma::Postgres::Model(:mobility_gbfs_feeds)
  plugin :column_encryption do |enc|
    enc.column :auth_token
  end

  many_to_one :vendor, key: :vendor_id, class: "Suma::Vendor"

  COMPONENTS_TO_INTERVALS = {
    geofencing_zones: 24.hours,
    free_bike_status: 30.seconds,
  }.freeze
  COMPONENTS_TO_ROUTINES = {
    geofencing_zones: Suma::Mobility::Gbfs::GeofencingZone,
    free_bike_status: Suma::Mobility::Gbfs::FreeBikeStatus,
  }.freeze
  SYNCABLE_COMPONENTS = COMPONENTS_TO_ROUTINES.keys.freeze

  dataset_module do
    def ready_to_sync(component, now:)
      return self.where(
        Sequel[:"#{component}_enabled"] &
        (Sequel[:"#{component}_synced_at"] < (now - COMPONENTS_TO_INTERVALS.fetch(component))),
      )
    end
  end

  def component_enabled?(component) = self.send(:"#{component}_enabled")

  def sync_component(component)
    Suma::Mobility::Gbfs::VendorSync.new(
      client: Suma::Mobility::Gbfs::HttpClient.new(api_host: self.feed_root_url, auth_token: self.auth_token),
      vendor: self.vendor,
      component: COMPONENTS_TO_ROUTINES.fetch(component.to_sym).new,
    ).sync_all
  end
end
