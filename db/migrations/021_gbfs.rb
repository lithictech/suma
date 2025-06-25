# frozen_string_literal: true

Sequel.migration do
  up do
    from(:mobility_restricted_areas).delete
    alter_table(:mobility_restricted_areas) do
      add_column :multipolygon, "decimal[][][][]", null: false
      add_column :title, :text, null: false
      add_column :unique_id, :text, null: false, unique: true
      add_foreign_key :vendor_service_id, :vendor_services, null: false
      drop_column :polygon
    end

    alter_table(:mobility_vehicles) do
      add_column :battery_level, :smallint, null: true
      add_constraint(:valid_battery_level, Sequel.lit("battery_level >= 0 AND battery_level <= 100"))
    end

    alter_table(:vendor_services) do
      add_column :constraints, :jsonb, null: true, default: "[]"
      drop_column :sync_url
    end

    alter_table(:mobility_trips) do
      add_column :external_trip_id, :text, null: true, unique: true
    end

    alter_table(:members) do
      add_column :lime_user_id, :text, null: false, default: ""
    end
  end
end
