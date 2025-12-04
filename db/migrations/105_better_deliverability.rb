# frozen_string_literal: true

require "sequel/null_or_present_constraint"

Sequel.migration do
  change do
    alter_table(:message_preferences) do
      add_column :sms_undeliverable_at, :timestamptz
    end
    alter_table(:marketing_sms_broadcasts) do
      add_column :preferences_optout_field, :text, null: false, default: ""
    end
  end
end
