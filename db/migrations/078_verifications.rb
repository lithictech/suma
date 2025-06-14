# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:organization_membership_verifications) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :status, null: false
      jsonb :partner_outreach_front_response
      jsonb :member_outreach_front_response

      foreign_key :membership_id, :organization_memberships, null: false
      foreign_key :owner_id, :members, on_delete: :set_null

      column :search_content, :text
      column :search_embedding, "vector(384)"
      column :search_hash, :text
      index Sequel.function(:to_tsvector, "english", :search_content),
            name: :organization_membership_verifications_search_content_tsvector_index,
            type: :gin
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
