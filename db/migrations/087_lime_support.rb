# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    alter_table(:commerce_checkouts) do
      drop_column :save_payment_instrument
    end
    create_table(:program_enrollment_exclusions) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :created_by_id, :members, on_delete: :set_null

      foreign_key :program_id, :programs, null: false, on_delete: :cascade, index: true
      foreign_key :member_id, :members, on_delete: :cascade, index: true
      foreign_key :role_id, :roles, on_delete: :cascade, index: true
      unique [:program_id, :member_id]
      unique [:program_id, :role_id]
      constraint(
        :one_enrollee_set,
        Sequel.unambiguous_constraint([:member_id, :role_id]),
      )
    end
  end
  down do
    alter_table(:commerce_checkouts) do
      add_column :save_payment_instrument, :boolean, default: false
    end
    drop_table(:program_enrollment_exclusions)
  end
end
