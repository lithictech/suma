# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    create_table(:programs) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :name_id, :translated_texts, null: false
      foreign_key :description_id, :translated_texts, null: false
      tstzrange :period, null: false

      float :ordinal, null: false, default: 0
    end

    create_join_table(
      {program_id: :programs, service_id: :vendor_services},
      name: :programs_vendor_services,
    )
    create_join_table(
      {program_id: :programs, offering_id: :commerce_offerings},
      name: :programs_commerce_offerings,
    )
    create_join_table(
      {program_id: :programs, configuration_id: :anon_proxy_vendor_configurations},
      name: :programs_anon_proxy_vendor_configurations,
    )
    create_join_table(
      {program_id: :programs, trigger_id: :payment_triggers},
      name: :programs_payment_triggers,
    )

    create_table(:program_enrollments) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :program_id, :programs, null: false, on_delete: :cascade

      foreign_key :member_id, :members, on_delete: :cascade
      foreign_key :organization_id, :organizations, on_delete: :cascade
      constraint(
        :one_enrollee_set,
        Sequel.unambiguous_constraint([:member_id, :organization_id]),
      )

      timestamptz :approved_at
      foreign_key :approved_by, :members, on_delete: :set_null
      timestamptz :unenrolled_at
      foreign_key :unenrolled_by, :members, on_delete: :set_null
    end

    alter_table(:images) do
      add_foreign_key :program_id, :programs, index: true
      drop_constraint(:unambiguous_relation)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint(
          [:commerce_product_id, :commerce_offering_id, :vendor_id, :vendor_service_id, :program_id],
        ),
      )
    end
  end

  down do
    # alter_table(:images) do
    #   drop_constraint(:unambiguous_relation)
    #   drop_column(:program_id)
    #   add_constraint(
    #     :unambiguous_relation,
    #     Sequel.unambiguous_constraint(
    #       [:commerce_product_id, :commerce_offering_id, :vendor_id, :vendor_service_id],
    #     ),
    #   )
    # end
    #
    # drop_table(:program_enrollments)
    # drop_table(:programs)
  end
end