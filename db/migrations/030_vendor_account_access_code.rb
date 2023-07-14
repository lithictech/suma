# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/null_or_present_constraint"

Sequel.migration do
  change do
    alter_table(:anon_proxy_vendor_accounts) do
      add_column :latest_access_code, :text, null: true
      add_column :latest_access_code_set_at, :timestamptz, null: true
      add_constraint(
        :consistent_latest_access_code,
        Sequel.all_or_none_constraint([:latest_access_code, :latest_access_code_set_at]),
      )
      add_constraint(
        :null_or_present_latest_access_code,
        Sequel.null_or_present_constraint(:latest_access_code),
      )
    end
  end
end
