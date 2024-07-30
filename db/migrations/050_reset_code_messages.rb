# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:member_reset_codes) do
      add_foreign_key :message_delivery_id, :message_deliveries
      add_column :canceled, :boolean, default: false
    end
  end
end
