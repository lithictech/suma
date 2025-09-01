# frozen_string_literal: true

Sequel.migration do
  up do
    # These are old tables noticed while doing this work, which were replaced by programs
    drop_table(:vendible_groups_vendor_services, if_exists: true)
    drop_table(:vendible_groups_commerce_offerings, if_exists: true)
    drop_table(:vendible_groups, if_exists: true)

    create_table(:program_pricings) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :program_id, :programs, null: false, on_delete: :cascade
      foreign_key :vendor_service_id, :vendor_services, null: false, on_delete: :cascade
      foreign_key :vendor_service_rate_id, :vendor_service_rates, null: false, on_delete: :cascade, index: true
      index [:program_id, :vendor_service_id], unique: true
    end
    alter_table(:vendor_service_rates) do
      add_column :ordinal, :float, null: false, default: 0
    end
    # While we know the link between vendor services and rates,
    # we don't know what program to associate them with.
    # The ProgramPricing will need to be created on production after deploy.
    alter_table(:programs) do
      drop_column :vendor_service_id
      drop_column :vendor_service_rate_id
    end
    drop_table :vendor_service_vendor_service_rates
    drop_table :programs_vendor_services
  end
  down do
    create_join_table(
      {vendor_service_id: :vendor_services, vendor_service_rate_id: :vendor_service_rates},
      name: :vendor_service_vendor_service_rates,
    )
    create_join_table(
      {program_id: :programs, service_id: :vendor_services},
      name: :programs_vendor_services,
    )
    alter_table(:programs) do
      add_foreign_key :vendor_service_id, :vendor_services
      add_foreign_key :vendor_service_rate_id, :vendor_service_rates
    end
    # Since we can't migrate back up with this data, we aren't going to worry about preserving it down,
    # though we could.
    alter_table(:vendor_service_rates) do
      drop_column :ordinal
    end
    drop_table(:program_pricings)
  end
end
