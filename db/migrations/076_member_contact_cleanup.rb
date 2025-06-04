# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:anon_proxy_member_contacts) do
      add_column :external_relay_id, :text, null: false, default: ""
    end
  end
end
