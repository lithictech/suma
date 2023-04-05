# frozen_string_literal: true

Sequel.migration do
  change do
    from(:mobility_restricted_areas).delete
    alter_table(:mobility_restricted_areas) do
      add_column :multipolygon, "decimal[][][][]", null: false
      add_column :title, :text, null: false
      add_column :unique_id, :text, null: false, unique: true
      drop_column :polygon
    end

    alter_table(:mobility_vehicles) do
      add_column :battery_level, :smallint, null: true
      add_constraint(:valid_battery_level, Sequel.lit("battery_level >= 0 AND battery_level <= 100"))
    end
  end
end
