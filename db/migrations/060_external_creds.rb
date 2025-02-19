# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/unambiguous_constraint"
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
  end
end
