# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:mobility_vehicles) do
      add_column :battery_level, Integer, null: true
    end
  end
end
