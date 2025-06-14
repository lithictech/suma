# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:organization_membership_verifications) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :status, null: false

      foreign_key :membership_id, :organization_memberships, null: false
      foreign_key :owner_id, :members, on_delete: :set_null
    end

    create_table(:organization_membership_verification_audit_logs) do
      primary_key :id
      timestamptz :at, null: false

      text :event, null: false
      text :to_state, null: false
      text :from_state, null: false
      text :reason, null: false, default: ""
      jsonb :messages, null: false, default: "[]"

      foreign_key :verification_id, :organization_membership_verifications, null: false
      foreign_key :actor_id, :members, on_delete: :set_null
    end
  end
  down do
    drop_table(:organization_membership_verification_audit_logs)
    drop_table(:organization_membership_verifications)
  end
end
