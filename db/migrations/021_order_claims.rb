# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_orders) do
      add_column :claimed_at, :timestamptz
    end
  end
end
