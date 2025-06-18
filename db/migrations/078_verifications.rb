# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:organizations) do
      add_column :membership_verification_email, :text, null: false, default: ""
      add_column :membership_verification_front_template_id, :text, null: false, default: ""
      add_foreign_key :membership_verification_member_outreach_template_id, :translated_texts
    end

    create_table(:organization_membership_verifications) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :status, null: false
      text :partner_outreach_front_conversation_id
      text :member_outreach_front_conversation_id

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

      foreign_key :verification_id, :organization_membership_verifications, null: false, on_delete: :cascade
      foreign_key :actor_id, :members, on_delete: :set_null
    end

    create_table(:organization_membership_verification_notes) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :edited_at

      text :content, null: false

      foreign_key :verification_id, :organization_membership_verifications, null: false, on_delete: :cascade
      foreign_key :creator_id, :members, on_delete: :set_null
      foreign_key :editor_id, :members, on_delete: :set_null
    end

    if ENV["RACK_ENV"] == "test"
      run <<~SQL
        CREATE TABLE front_message_v1_fixture (
          pk bigserial PRIMARY KEY,
          front_id text UNIQUE NOT NULL,
          type text,
          front_conversation_id text,
          created_at timestamptz,
          data jsonb NOT NULL
        );
        CREATE TABLE front_conversation_v1_fixture (
          pk bigserial PRIMARY KEY,
          front_id text UNIQUE NOT NULL,
          subject text,
          status text,
          created_at timestamptz,
          data jsonb NOT NULL
        );
      SQL
    end
  end
  down do
    drop_table(:organization_membership_verification_audit_logs)
    drop_table(:organization_membership_verification_notes)
    drop_table(:organization_membership_verifications)
    alter_table(:organizations) do
      drop_column :membership_verification_email
      drop_column :membership_verification_front_template_id
      drop_column :membership_verification_member_outreach_template_id
    end
    run "DROP TABLE front_message_v1_fixture; DROP TABLE front_conversation_v1_fixture;" if ENV["RACK_ENV"] == "test"
  end
end
