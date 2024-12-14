# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:message_preferences) do
      add_column :marketing_optout, :boolean, null: false, default: false
    end
  end
end
