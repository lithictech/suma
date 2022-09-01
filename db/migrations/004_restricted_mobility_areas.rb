# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:mobility_restricted_areas) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      decimal :ne_lat, null: false
      decimal :ne_lng, null: false
      decimal :sw_lat, null: false
      decimal :sw_lng, null: false
      column :polygon, "decimal[][]", null: false
      text :restriction, null: true
    end
  end
end
