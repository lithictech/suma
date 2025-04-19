# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:mobility_gbfs_feeds) do
      primary_key :id
      foreign_key :vendor_id, :vendors, null: false
      text :feed_root_url, null: false
      text :auth_token

      boolean :geofencing_zones_enabled, null: false, default: false
      timestamptz :geofencing_zones_synced_at, null: false, default: Time.at(0)
      boolean :free_bike_status_enabled, null: false, default: false
      timestamptz :free_bike_status_synced_at, null: false, default: Time.at(0)
    end
  end
end
