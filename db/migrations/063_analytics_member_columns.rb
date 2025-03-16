# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(Sequel[:analytics][:members]) do
      add_column :onboarding_verified, :boolean
      add_column :preferred_language, :text
      add_column :account_updates_sms_optout, :boolean
      add_column :marketing_sms_optout, :boolean
    end
  end
end
