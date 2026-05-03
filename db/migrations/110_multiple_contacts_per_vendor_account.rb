# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:anon_proxy_member_contacts) do
      drop_index([], name: :anon_proxy_member_contacts_email_relay_key_key)
      drop_index([], name: :anon_proxy_member_contacts_phone_relay_key_key)
      add_index :email
      add_index :phone
    end
  end

  down do
    alter_table(:anon_proxy_member_contacts) do
      drop_index :email
      drop_index :phone
      add_index [:email, :relay_key], unique: true, name: :anon_proxy_member_contacts_email_relay_key_key
      add_index [:phone, :relay_key], unique: true, name: :anon_proxy_member_contacts_phone_relay_key_key
    end
  end
end
