# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:anon_proxy_vendor_configurations) do
      add_column :auth_url, :text, null: false
      add_column :auth_http_method, :text, null: false, default: 'POST'
      add_column :auth_content_type, :text, null: false
      add_column :auth_params, :jsonb, null: false
      add_column :auth_headers, :jsonb, null: false
      rename_column :app_launch_link, :app_install_link
    end

    alter_table(:anon_proxy_vendor_accounts) do
      add_column :latest_access_code_requested_at, :timestamptz
      add_column :latest_access_code_magic_link, :text
    end
  end
end
