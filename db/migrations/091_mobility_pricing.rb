# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:vendor_services) do
      drop_column :charge_after_fulfillment
    end
  end
  down do
    alter_table(:vendor_services) do
      add_column :charge_after_fulfillment, :bool
    end
  end
end
