# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  change do
    create_table(:anon_proxy_member_contacts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :phone, null: true
      text :email, null: true
      constraint(
        :unambiguous_address,
        Sequel.unambiguous_constraint([:phone, :email]),
      )
      text :provider_key, null: false
      # We may have to reuse the same email or phone between providers.
      unique [:phone, :provider_key]
      unique [:email, :provider_key]

      foreign_key :member_id, :members, null: false, on_delete: :cascade, index: true
    end

    create_table(:anon_proxy_vendor_configurations) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :vendor_id, :vendors, null: false, on_delete: :cascade, unique: true
      text :logic_adapter_key, null: false

      boolean :uses_email, null: false
      boolean :uses_sms, null: false
      constraint(:unambiguous_contact_type, Sequel.unambiguous_bool_constraint([:uses_email, :uses_sms]))

      boolean :enabled, null: false
    end

    create_table(:anon_proxy_vendor_accounts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :configuration_id, :anon_proxy_vendor_configurations, null: false, on_delete: :cascade, index: true
      foreign_key :member_id, :members, null: false, on_delete: :cascade, index: true
      foreign_key :contact_id, :anon_proxy_member_contacts, null: true, on_delete: :set_null, index: true
    end

    alter_table(:images) do
      add_foreign_key :vendor_id, :vendors, index: true
      drop_constraint(:unambiguous_relation)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint([:commerce_product_id, :commerce_offering_id, :vendor_id]),
      )
    end
  end
end
