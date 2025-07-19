# frozen_string_literal: true

require "sequel/null_or_present_constraint"

Sequel.migration do
  up do
    create_table(:anon_proxy_vendor_account_registrations) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)

      foreign_key :account_id, :anon_proxy_vendor_accounts, index: true, null: false, on_delete: :cascade
      text :external_program_id, null: false
      text :external_registration_id
      constraint(
        :non_empty_external_registration_id,
        Sequel.null_or_present_constraint(:external_registration_id),
      )
    end

    from(:anon_proxy_vendor_accounts).exclude(registered_with_vendor: nil).each do |row|
      r = JSON.parse(row.fetch(:registered_with_vendor))
      r.each do |lyft_id, enrolled_at|
        from(:anon_proxy_vendor_account_registrations).insert(
          created_at: enrolled_at.present? ? Time.parse(enrolled_at) : Time.now,
          account_id: row.fetch(:id),
          external_program_id: lyft_id,
        )
      end
    end

    alter_table(:anon_proxy_vendor_accounts) do
      rename_column :registered_with_vendor, :legacy_registered_with_vendor
      add_column :pending_closure, :boolean, default: false
    end
  end
  down do
    drop_table(:anon_proxy_vendor_account_registrations)
    alter_table(:anon_proxy_vendor_accounts) do
      rename_column :legacy_registered_with_vendor, :registered_with_vendor
      drop_column :pending_closure
    end
  end
end
