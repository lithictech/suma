# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:anon_proxy_member_contacts) do
      # Originally the idea is that, the use of the phone number is implied by the relay.
      # But it turns out this is just more confusing, and doesn't add anything to the modeling
      # or future flexibility, so name the contact fields the same as the relay transports.
      rename_column :phone, :sms
    end
  end
end
