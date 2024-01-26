# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:message_preferences) do
      add_column :access_token, :text, null: true, unique: true
      add_column :account_updates_optout, :boolean, null: false, default: false
    end
    from(:message_preferences).each do |row|
      from(:message_preferences).where(id: row.fetch(:id)).update(access_token: SecureRandom.uuid)
    end
    alter_table(:message_preferences) do
      set_column_not_null :access_token
    end
  end
  down do
    alter_table(:message_preferences) do
      drop_column :access_token
      drop_column :account_updates_optout
    end
  end
end
