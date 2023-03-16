# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:mobility_restricted_areas) do
      add_column :multipolygon, "decimal[][][]", null: true
      add_column :title, :text, null: false, default: ""
      add_column :unique_id, :text, null: false, unique: true
      set_column_allow_null :polygon
      set_column_allow_null :ne_lat
      set_column_allow_null :ne_lng
      set_column_allow_null :sw_lat
      set_column_allow_null :sw_lng
    end
  end
end
