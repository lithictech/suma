# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:vendors) do
      drop_column :organization_id
    end
    drop_table(:vendor_service_market_constraints)
    drop_table(:vendor_service_organization_constraints)
    drop_table(:vendor_service_role_constraints)
    drop_table(:vendor_service_matchall_constraints)
    drop_table(:organizations)
  end
end
