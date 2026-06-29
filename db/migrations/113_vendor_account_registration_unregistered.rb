# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:anon_proxy_vendor_account_registrations) do
      add_column :unregistered_at, :timestamptz
    end
  end
end
