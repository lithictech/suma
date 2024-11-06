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

      text :app_link, null: false, default: ""
      foreign_key :app_link_text_id, :translated_texts, null: false
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

      foreign_key :program_id, :programs, null: false, on_delete: :cascade, index: true

      foreign_key :member_id, :members, on_delete: :cascade, index: true
      foreign_key :organization_id, :organizations, on_delete: :cascade, index: true
      constraint(
        :one_enrollee_set,
        Sequel.unambiguous_constraint([:member_id, :organization_id]),
      )

      index [
        Sequel.function(:coalesce, :member_id, 0),
        Sequel.function(:coalesce, :organization_id, 0),
        :program_id,
      ],
            name: :unique_enrollee_in_program_idx,
            unique: true

      timestamptz :approved_at, index: true
      foreign_key :approved_by_id, :members, on_delete: :set_null
      timestamptz :unenrolled_at, index: true
      foreign_key :unenrolled_by_id, :members, on_delete: :set_null
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
    alter_table(:images) do
      drop_constraint(:unambiguous_relation)
      drop_column(:program_id)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint(
          [:commerce_product_id, :commerce_offering_id, :vendor_id, :vendor_service_id],
        ),
      )
    end

    drop_table(:program_enrollments)
    drop_table(:programs_vendor_services)
    drop_table(:programs_commerce_offerings)
    drop_table(:programs_anon_proxy_vendor_configurations)
    drop_table(:programs_payment_triggers)
    drop_table(:programs)
  end
end
