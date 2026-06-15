# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:anon_proxy_vendor_configurations) do
      add_column :platform_payment_never_required, :boolean, null: false, default: false
    end
  end
end
