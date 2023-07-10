# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:mobility_vehicles) do
      add_column :rental_uris, :jsonb, null: false, default: "{}"
    end
  end
end
