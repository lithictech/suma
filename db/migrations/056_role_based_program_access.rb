# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    alter_table(:program_enrollments) do
      add_foreign_key :role_id, :roles, on_delete: :cascade, index: true

      drop_constraint(:one_enrollee_set)
      add_constraint(
        :one_enrollee_set,
        Sequel.unambiguous_constraint([:member_id, :organization_id, :role_id]),
      )

      drop_index(:program_id, name: :unique_enrollee_in_program_idx)
      add_index [
        Sequel.function(:coalesce, :member_id, 0),
        Sequel.function(:coalesce, :organization_id, 0),
        Sequel.function(:coalesce, :role_id, 0),
        :program_id,
      ],
                name: :unique_enrollee_in_program_idx,
                unique: true
    end
  end

  down do
    alter_table(:program_enrollments) do
      drop_index(:program_id, name: :unique_enrollee_in_program_idx)
      add_index [
        Sequel.function(:coalesce, :member_id, 0),
        Sequel.function(:coalesce, :organization_id, 0),
        :program_id,
      ],
                name: :unique_enrollee_in_program_idx,
                unique: true

      drop_constraint(:one_enrollee_set)
      add_constraint(
        :one_enrollee_set,
        Sequel.unambiguous_constraint([:member_id, :organization_id]),
      )
      drop_column(:role_id)
    end
  end
end
