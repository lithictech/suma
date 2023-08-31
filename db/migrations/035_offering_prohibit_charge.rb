# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_offerings) do
      add_column :prohibit_charge_at_checkout, :boolean, default: false
    end
  end
end
