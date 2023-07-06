# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    create_table(:eligibility_constraints) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :name, null: false
    end

    create_table(:eligibility_member_associations) do
      primary_key :id

      foreign_key :constraint_id, :eligibility_constraints, null: false

      foreign_key :verified_member_id, :members
      foreign_key :pending_member_id, :members
      foreign_key :rejected_member_id, :members

      column :effective_member_id, :integer, generated_always_as: Sequel.function(
        :coalesce,
        :verified_member_id,
        :pending_member_id,
        :rejected_member_id,
      )

      index [:effective_member_id, :constraint_id],
            name: :unique_member_idx,
            unique: true

      constraint(
        :one_member_set,
        Sequel.unambiguous_constraint(
          [
            :verified_member_id,
            :pending_member_id,
            :rejected_member_id,
          ],
        ),
      )
    end

    create_join_table(
      {constraint_id: :eligibility_constraints, offering_id: :commerce_offerings},
      name: :eligibility_offering_associations,
    )

    run("ALTER TABLE eligibility_member_associations ADD CONSTRAINT unique_member UNIQUE USING INDEX unique_member_idx")
  end
end
