# frozen_string_literal: true

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

      foreign_key :member_id, :members, null: false, index: true
      foreign_key :organization_id, :organizations, null: false, index: true
      index [:member_id, :organization_id], unique: true
    end
  end
end
