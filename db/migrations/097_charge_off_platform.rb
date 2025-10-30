# frozen_string_literal: true

require "sequel/all_or_none_constraint"

Sequel.migration do
  up do
    alter_table(:charges) do
      add_column :off_platform_amount_cents, :integer, default: 0, null: false
      add_column :off_platform_amount_currency, :text, default: "USD", null: false
    end

    # Move all book transactions over to the 'contributing' table,
    # and update line items to have the amount and memo directly.
    create_join_table(
      {charge_id: :charges, book_transaction_id: :payment_book_transactions},
      name: :charges_contributing_book_transactions,
    ) do
      unique :book_transaction_id
    end
    alter_table(:charge_line_items) do
      add_column :amount_cents, :integer
      add_column :amount_currency, :text
      add_foreign_key :memo_id, :translated_texts
    end
    # 'self data' line items are totally rethought and will be re-imported.
    from(:charge_line_items).where(book_transaction_id: nil).delete
    # Now merge the book transactions into the line items that were using them.
    from(:charge_line_items).exclude(book_transaction_id: nil).each do |cli|
      bx = from(:payment_book_transactions).where(id: cli.fetch(:book_transaction_id)).first
      from(:charges_contributing_book_transactions).
        insert(charge_id: cli.fetch(:charge_id), book_transaction_id: bx.fetch(:id))
      from(:charge_line_items).where(id: cli.fetch(:id)).update(
        amount_cents: bx.fetch(:amount_cents),
        amount_currency: bx.fetch(:amount_currency),
        memo_id: bx.fetch(:memo_id),
      )
    end
    alter_table(:charge_line_items) do
      set_column_not_null :amount_cents
      set_column_not_null :amount_currency
      set_column_not_null :memo_id
      drop_column :book_transaction_id
      drop_column :self_data_id
    end
    drop_table(:charge_line_item_self_datas)

    alter_table(:mobility_trips) do
      add_column :our_cost_cents, :integer, default: 0, null: false
      add_column :our_cost_currency, :text, default: "USD", null: false
    end

    alter_table(:vendor_service_rates) do
      drop_column :localization_key
      rename_column :name, :internal_name
      add_column :external_name, :text, null: true
    end
    from(:vendor_service_rates).update(external_name: :internal_name)
    alter_table(:vendor_service_rates) do
      set_column_not_null :external_name
    end

    alter_table(Sequel[:analytics][:trips]) do
      drop_column :paid_cost
      add_column :paid_off_platform, :decimal
    end
    alter_table(Sequel[:analytics][:orders]) do
      drop_column :paid_cost
      add_column :paid_off_platform, :decimal
    end
  end
end
