# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:members) do
      add_column :oye_contact_id, :text, null: false, default: ""
    end
    alter_table(:message_preferences) do
      add_column :marketing_optout, :boolean, null: false, default: false
    end
  end
end
