# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  change do
    create_table(:organizations) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      text :name, null: false, unique: true
    end

    create_table(:organization_memberships) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :organization_id, :organizations, null: false, index: true
      foreign_key :verified_member_id, :members, index: true
      foreign_key :unverified_member_id, :members, index: true
      constraint(
        :unambiguous_member,
        Sequel.unambiguous_constraint([:verified_member_id, :unverified_member_id]),
      )
    end
  end
end
