# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:commerce_products) do
      drop_column :our_cost_cents
      drop_column :our_cost_currency
    end
  end
  down do
    alter_table(:commerce_products) do
      add_column :our_cost_cents, :integer, default: 0
      add_column :our_cost_currency, :text, default: ""
    end
  end
end
