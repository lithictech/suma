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

      foreign_key :verified_organization_id, :organizations, index: true
      text :unverified_organization_name

      foreign_key :member_id, :members, index: true
      constraint(
        :unambiguous_verification_status,
        Sequel.unambiguous_constraint([:verified_organization_id, :unverified_organization_name]),
      )
    end
  end
end
