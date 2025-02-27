# frozen_string_literal: true

require "sequel/unambiguous_constraint"
require "sequel/null_or_present_constraint"
require "suma/secureid"

Sequel.migration do
  up do
    create_table(:external_credentials) do
      primary_key :id
      text :service, null: false, unique: true
      timestamptz :expires_at, null: true
      text :data, null: false
    end

    create_table(:charge_line_item_self_datas) do
      primary_key :id
      int :amount_cents, null: false
      text :amount_currency, null: false
      foreign_key :memo_id, :translated_texts, null: false
    end

    create_table(:charge_line_items) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      text :opaque_id, null: false, unique: true
      foreign_key :charge_id, :charges, null: false, on_delete: :cascade
      index :charge_id

      # We can't easily do unambiguous constraints on the memo/amount fields due to plugins,
      # so add a level of indirection.
      foreign_key :book_transaction_id, :payment_book_transactions, on_delete: :restrict, null: true, unique: true
      foreign_key :self_data_id, :charge_line_item_self_datas, on_delete: :restrict, null: true, unique: true

      constraint(
        :self_data_or_book_transaction_data_set,
        Sequel.unambiguous_constraint([:book_transaction_id, :self_data_id]),
      )
    end

    rows = from(:charges_payment_book_transactions).all.map do |r|
      r.merge!(opaque_id: Suma::Secureid.new_opaque_id("chi"))
    end
    from(:charge_line_items).multi_insert(rows)

    drop_table(:charges_payment_book_transactions)

    alter_table(:vendor_services) do
      add_column :charge_after_fulfillment, :boolean, default: false, null: false
    end

    alter_table(:mobility_trips) do
      add_column :opaque_id, :text, unique: true
    end
    from(:mobility_trips).each do |t|
      id = t.delete(:id)
      t[:opaque_id] = Suma::Secureid.new_opaque_id("trp")
      from(:mobility_trips).where(id:).update(t)
    end
    alter_table(:mobility_trips) do
      set_column_not_null :opaque_id
    end

    alter_table(:anon_proxy_vendor_configurations) do
      add_column :auth_to_vendor_key, :text
      add_foreign_key :linked_success_instructions_id, :translated_texts
    end
    linked_success_instructions_id = from(:translated_texts).insert(
      en: "We sent you a text, please click the link to open the Lime app.",
      es: "We sent you a text, please click the link to open the Lime app.",
    )
    from(:anon_proxy_vendor_configurations).update(
      auth_to_vendor_key: "lime",
      linked_success_instructions_id:,
    )
    alter_table(:anon_proxy_vendor_configurations) do
      set_column_not_null :auth_to_vendor_key
      set_column_not_null :linked_success_instructions_id

      drop_column :auth_http_method
      drop_column :auth_url
      drop_column :auth_headers
      drop_column :auth_body_template

      add_column :uses_registration, :boolean, default: false, null: false
      drop_constraint(:unambiguous_contact_type)
      add_constraint(
        :unambiguous_contact_type,
        Sequel.unambiguous_bool_constraint([:uses_email, :uses_sms, :uses_registration]),
      )
    end
    alter_table(:anon_proxy_vendor_accounts) do
      add_column :registered_with_vendor, :text
      add_constraint(
        :non_empty_vendor_registration,
        Sequel.null_or_present_constraint(:registered_with_vendor),
      )
    end
  end

  down do
    create_join_table(
      {charge_id: :charges, book_transaction_id: :payment_book_transactions},
      name: :charges_payment_book_transactions,
    )
    from(:charges_payment_book_transactions).multi_insert(
      from(:charge_line_items).exclude(book_transaction_id: nil).select(:charge_id, :book_transaction_id).all,
    )
    drop_table(:charge_line_items)
    drop_table(:charge_line_item_self_datas)
    drop_table(:external_credentials)

    alter_table(:vendor_services) do
      drop_column :charge_after_fulfillment
    end
    alter_table(:mobility_trips) do
      drop_column :opaque_id
    end
    alter_table(:anon_proxy_vendor_configurations) do
      drop_column :auth_to_vendor_key
      drop_column :linked_success_instructions_id
      drop_column :uses_registration
      add_constraint(
        :unambiguous_contact_type,
        Sequel.unambiguous_bool_constraint([:uses_email, :uses_sms]),
      )
      add_column :auth_http_method, :text
      add_column :auth_url, :text
      add_column :auth_headers, :text
      add_column :auth_body_template, :text
    end
    alter_table(:anon_proxy_vendor_accounts) do
      drop_column :registered_with_vendor
    end
  end
end
