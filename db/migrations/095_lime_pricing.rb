# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:mobility_vendor_adapters) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      boolean :uses_deep_linking, null: false, default: false
      foreign_key :vendor_service_id, :vendor_services, null: false, unique: true
      text :trip_provider_key, null: false, default: ""

      boolean :send_receipts, null: false, default: false

      constraint(
        :deeplink_cohesion,
        (Sequel[:uses_deep_linking] & (Sequel[:trip_provider_key] =~ "")) |
        (~Sequel[:uses_deep_linking] & (Sequel[:trip_provider_key] !~ "")),
      )
    end
    alter_table(:vendor_services) do
      drop_column :mobility_vendor_adapter_key
    end
  end
  down do
    drop_table(:mobility_vendor_adapters)
    alter_table(:vendor_services) do
      add_column :mobility_vendor_adapter_key, :text
    end
  end
end
