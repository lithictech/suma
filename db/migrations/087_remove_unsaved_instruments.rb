# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:commerce_checkouts) do
      drop_column :save_payment_instrument
    end
  end
  down do
    alter_table(:commerce_checkouts) do
      add_column :save_payment_instrument, :boolean, default: false
    end
  end
end
