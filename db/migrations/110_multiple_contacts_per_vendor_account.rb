# frozen_string_literal: true

Sequel.migration do
  tbl = :anon_proxy_member_contacts
  up do
    # Coming from the previous migration, we need to drop the constraint (since the index depends on it),
    # but using add_index in the DOWN, then coming back UP, we don't have the constraint,
    # we have to drop the index. I am not really sure why.
    run "ALTER TABLE #{tbl} DROP CONSTRAINT IF EXISTS anon_proxy_member_contacts_email_relay_key_key"
    run "ALTER TABLE #{tbl} DROP CONSTRAINT IF EXISTS anon_proxy_member_contacts_phone_relay_key_key"
    alter_table tbl do
      drop_index([], name: :anon_proxy_member_contacts_email_relay_key_key, if_exists: true)
      drop_index([], name: :anon_proxy_member_contacts_phone_relay_key_key, if_exists: true)
      add_index :email
      add_index :phone
    end
  end

  down do
    alter_table tbl do
      drop_index :email
      drop_index :phone
      add_index [:email, :relay_key], unique: true, name: :anon_proxy_member_contacts_email_relay_key_key
      add_index [:phone, :relay_key], unique: true, name: :anon_proxy_member_contacts_phone_relay_key_key
    end
  end
end
