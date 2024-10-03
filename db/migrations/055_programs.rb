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

      boolean :is_utility, null: false, default: false
    end

    create_table(:program_enrollments) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :member_id, :members, null: false, on_delete: :cascade
      foreign_key :program_id, :programs, null: false, on_delete: :cascade

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
    drop_table(:programs)
  end
end
