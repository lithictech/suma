# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:organization_registration_links) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at
      foreign_key :created_by_id, :members, on_delete: :set_null

      foreign_key :organization_id, :organizations, null: false, index: true, on_delete: :cascade

      text :opaque_id, null: false, unique: true
      text :rrule, null: false, default: ""
    end

    alter_table(:organization_memberships) do
      add_foreign_key :registration_link_id, :organization_registration_links, index: true
    end
  end
end
