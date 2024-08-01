# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/null_or_present_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    create_table(:vendible_groups) do
      primary_key :id
      foreign_key :name_id, :translated_texts, null: false
      float :ordinal, null: false, default: 0
    end

    alter_table(:vendor_services) do
      add_column :period, :tstzrange
    end
    from(:vendor_services).
      update(period: Sequel.pg_range(Time.new(2024, 5, 1)..Time.new(2024, 12, 31).end_of_day))
    alter_table(:vendor_services) do
      set_column_not_null :period
    end

    alter_table(:images) do
      add_foreign_key :vendor_service_id, :vendor_services, index: true
      drop_constraint(:unambiguous_relation)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint([:commerce_product_id, :commerce_offering_id, :vendor_id, :vendor_service_id]),
      )
    end

    create_join_table(
      {
        group_id: :vendible_groups,
        service_id: :vendor_services,
      },
      name: :vendible_groups_vendor_services,
    )

    create_join_table(
      {
        group_id: :vendible_groups,
        offering_id: :commerce_offerings,
      },
      name: :vendible_groups_commerce_offerings,
    )
  end

  down do
    alter_table(:vendor_services) do
      drop_column :period
    end
    alter_table(:images) do
      drop_constraint(:unambiguous_relation)
      drop_column :vendor_service_id
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint([:commerce_product_id, :commerce_offering_id, :vendor_id]),
      )
    end
    drop_table(:vendible_groups_vendor_services)
    drop_table(:vendible_groups_commerce_offerings)
    drop_table(:vendible_groups)
  end
end
