# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
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
      text :relay_key, null: false
      # We may have to reuse the same email or phone between relays.
      unique [:phone, :relay_key]
      unique [:email, :relay_key]

      foreign_key :member_id, :members, null: false, on_delete: :cascade, index: true
    end

    create_table(:anon_proxy_vendor_configurations) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :vendor_id, :vendors, null: false, on_delete: :cascade, unique: true

      boolean :uses_email, null: false
      boolean :uses_sms, null: false
      constraint(:unambiguous_contact_type, Sequel.unambiguous_bool_constraint([:uses_email, :uses_sms]))

      text :message_handler_key, null: false
      text :app_launch_link, null: false

      boolean :enabled, null: false

      foreign_key :instructions_id, :translated_texts, null: false
    end

    create_table(:anon_proxy_vendor_accounts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      foreign_key :configuration_id, :anon_proxy_vendor_configurations, null: false, on_delete: :cascade, index: true
      foreign_key :member_id, :members, null: false, on_delete: :cascade, index: true
      foreign_key :contact_id, :anon_proxy_member_contacts, null: true, on_delete: :set_null, index: true

      unique [:configuration_id, :contact_id]
    end

    create_table(:anon_proxy_vendor_account_messages) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)

      text :message_id, null: false
      text :message_from, null: false
      text :message_to, null: false
      text :message_content, null: false
      timestamptz :message_timestamp, null: false

      text :relay_key, null: false
      text :message_handler_key, null: false

      foreign_key :vendor_account_id, :anon_proxy_vendor_accounts, null: false, on_delete: :cascade, index: true
      foreign_key :outbound_delivery_id, :message_deliveries, null: false, unique: true
    end

    alter_table(:images) do
      add_foreign_key :vendor_id, :vendors, index: true
      drop_constraint(:unambiguous_relation)
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint([:commerce_product_id, :commerce_offering_id, :vendor_id]),
      )
    end

    if ENV["RACK_ENV"] == "test"
      run <<~SQL
        CREATE TABLE public.postmark_inbound_message_v1_fixture (
          pk bigserial PRIMARY KEY,
          message_id text UNIQUE NOT NULL,
          from_email text,
          to_email text,
          subject text,
          timestamp timestamptz,
          tag text,
          data jsonb NOT NULL
        );
        CREATE INDEX IF NOT EXISTS svi_fixture_from_email_idx ON public.postmark_inbound_message_v1_fixture (from_email);
        CREATE INDEX IF NOT EXISTS svi_fixture_to_email_idx ON public.postmark_inbound_message_v1_fixture (to_email);
        CREATE INDEX IF NOT EXISTS svi_fixture_subject_idx ON public.postmark_inbound_message_v1_fixture (subject);
        CREATE INDEX IF NOT EXISTS svi_fixture_timestamp_idx ON public.postmark_inbound_message_v1_fixture (timestamp);
        CREATE INDEX IF NOT EXISTS svi_fixture_tag_idx ON public.postmark_inbound_message_v1_fixture (tag);
      SQL
    end
  end

  down do
    drop_table(:anon_proxy_vendor_accounts)
    drop_table(:anon_proxy_vendor_configurations)
    drop_table(:anon_proxy_member_contacts)
    from(:images).exclude(vendor_id: nil).delete
    alter_table(:images) do
      drop_constraint(:unambiguous_relation)
      drop_column :vendor_id
      add_constraint(
        :unambiguous_relation,
        Sequel.unambiguous_constraint([:commerce_product_id, :commerce_offering_id]),
      )
    end
    run("DROP TABLE postmark_inbound_message_v1_fixture") if ENV["RACK_ENV"] == "test"
  end
end
