# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_offerings) do
      add_column :confirmation_template, :text, null: false, default: ""
    end

    create_table(:message_preferences) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :member_id, :members, null: false, unique: true

      text :preferred_language, null: false
      boolean :sms_enabled, null: false
      boolean :email_enabled, null: false
    end

    alter_table(:message_deliveries) do
      add_column :template_language, :text, null: false, default: ""
    end
  end
end
