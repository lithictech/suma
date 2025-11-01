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

    # Trips keep track of what we paid, like products.
    # Only applies to trips we get invoiced for (Lime).
    alter_table(:mobility_trips) do
      add_column :our_cost_cents, :integer, default: 0, null: false
      add_column :our_cost_currency, :text, default: "USD", null: false
    end

    # Rates have names, not localization info.
    alter_table(:vendor_service_rates) do
      drop_column :localization_key
      rename_column :name, :internal_name
      add_column :external_name, :text, null: true
    end
    from(:vendor_service_rates).update(external_name: :internal_name)
    alter_table(:vendor_service_rates) do
      set_column_not_null :external_name
    end

    # Remove this ambiguous column, and add the new columns.
    alter_table(Sequel[:analytics][:trips]) do
      drop_column :paid_cost
      add_column :paid_off_platform, :decimal
      add_column :our_cost, :decimal
    end
    alter_table(Sequel[:analytics][:orders]) do
      drop_column :paid_cost
      add_column :paid_off_platform, :decimal
    end

    # Only off-platform fundings can fail to originate a book transaction.
    # But we have some funding transactions without them as a result of previous bugs.
    # Run this in a console before the migration:
    from(:payment_funding_transactions).
      where(originated_book_transaction_id: nil, off_platform_strategy_id: nil).
      each do |row|
      associated_vendor_service_category = from(:vendor_service_categories).
        where(slug: "cash").
        first
      receiving_ledger = from(:payment_ledgers).
        where(name: "Cash", account_id: row[:originating_payment_account_id]).
        first
      require "suma/secureid"
      bx_params = {
        amount_cents: row[:amount_cents],
        amount_currency: row[:amount_currency],
        apply_at: row[:created_at],
        originating_ledger_id: row[:platform_ledger_id],
        receiving_ledger_id: receiving_ledger.fetch(:id),
        associated_vendor_service_category_id: associated_vendor_service_category.fetch(:id),
        memo_id: row[:memo_id],
        opaque_id: Suma::Secureid.new_opaque_id("bx"),
      }
      bx_id = from(:payment_book_transactions).insert(bx_params)
      from(:payment_funding_transactions).where(id: row[:id]).update(
        originated_book_transaction_id: bx_id,
      )
    end

    # Funding transactions MUST have a book transaction when created,
    # or we are at risk of creating many conflicting charges while they are processing.
    alter_table(:payment_funding_transactions) do
      add_constraint(
        :originated_book_transaction_off_platform_consistency,
        ((Sequel[:off_platform_strategy_id] =~ nil) & (Sequel[:originated_book_transaction_id] !~ nil)) |
        ((Sequel[:off_platform_strategy_id] !~ nil) & (Sequel[:originated_book_transaction_id] =~ nil)),
      )
    end
  end
end
