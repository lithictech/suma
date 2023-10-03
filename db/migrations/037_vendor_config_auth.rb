# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:anon_proxy_vendor_configurations) do
      rename_column :app_launch_link, :app_install_link
      add_column :auth_http_method, :text, null: false, default: "POST"
      add_column :auth_url, :text, null: true
      add_column :auth_headers, :jsonb, null: true
      add_column :auth_body_template, :text, null: true
    end

    from(:anon_proxy_vendor_configurations).update(
      auth_url: "migrated",
      auth_headers: "{}",
      auth_body_template: "migrated",
    )

    alter_table(:anon_proxy_vendor_configurations) do
      set_column_not_null :auth_url
      set_column_not_null :auth_headers
      set_column_not_null :auth_body_template
    end

    alter_table(:anon_proxy_vendor_accounts) do
      add_column :latest_access_code_requested_at, :timestamptz
      add_column :latest_access_code_magic_link, :text
      add_index [:member_id, :configuration_id], unique: true
    end

    alter_table(:anon_proxy_vendor_account_messages) do
      set_column_allow_null :outbound_delivery_id
    end
  end
  down do
    alter_table(:anon_proxy_vendor_configurations) do
      rename_column :app_install_link, :app_launch_link
      drop_column :auth_http_method
      drop_column :auth_url
      drop_column :auth_headers
      drop_column :auth_body_template
    end

    alter_table(:anon_proxy_vendor_accounts) do
      drop_column :latest_access_code_requested_at
      drop_column :latest_access_code_magic_link
      drop_index [:member_id, :configuration_id]
    end
  end
end
