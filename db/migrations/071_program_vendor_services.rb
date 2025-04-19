# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:programs) do
      add_foreign_key :vendor_service_id, :vendor_services
      add_foreign_key :vendor_service_rate_id, :vendor_service_rates
    end
  end
end
