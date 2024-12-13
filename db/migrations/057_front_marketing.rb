# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:message_preferences) do
      rename_column :account_updates_optout, :account_updates_sms_optout
      add_column :account_updates_email_optout, :boolean, default: false, null: false
      add_column :marketing_sms_optout, :boolean, default: false, null: false
      add_column :marketing_email_optout, :boolean, default: false, null: false
    end
  end
end
