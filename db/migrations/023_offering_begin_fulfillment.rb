# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_offerings) do
      add_column :begin_fulfillment_at, :timestamptz, null: true, index: true
    end
  end
end
