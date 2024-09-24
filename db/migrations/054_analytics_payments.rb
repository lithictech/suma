# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(Sequel[:analytics][:ledgers]) do
      add_column :categories, "text[]"
    end

    create_table(Sequel[:analytics][:charges]) do
      primary_key :pk
      integer :charge_id, unique: true, null: false

      timestamptz :created_at
      text :opaque_id
      integer :member_id
      integer :order_id
      integer :trip_id
      decimal :discounted_subtotal
      decimal :discount_amount
      decimal :undiscounted_subtotal
      decimal :cash_paid
      decimal :noncash_paid
    end

    create_table(Sequel[:analytics][:book_transactions]) do
      primary_key :pk
      integer :book_transaction_id, unique: true, null: false

      timestamptz :created_at
      timestamptz :apply_at
      text :opaque_id
      integer :originating_member_id
      integer :originating_ledger_id
      integer :receiving_member_id
      integer :receiving_ledger_id
      integer :category_id
      text :category_name
      text :memo
      decimal :amount
      column :usage_codes, "text[]"

      boolean :is_cash
      boolean :platform_originating
      boolean :platform_receiving
    end

    create_table(Sequel[:analytics][:funding_transactions]) do
      primary_key :pk
      integer :funding_transaction_id, unique: true, null: false

      timestamptz :created_at
      timestamptz :updated_at
      text :status
      decimal :amount
      text :memo
      integer :originating_payment_account_id
      integer :originating_member_id
      integer :platform_ledger_id
      integer :originated_book_transaction_id
      column :usage_codes, "text[]"
      text :strategy_name
    end

    create_table(Sequel[:analytics][:payout_transactions]) do
      primary_key :pk
      integer :payout_transaction_id, unique: true, null: false

      timestamptz :created_at
      timestamptz :updated_at
      text :status
      decimal :amount
      text :memo
      integer :originating_payment_account_id
      integer :originating_member_id
      integer :platform_ledger_id
      integer :originated_book_transaction_id
      integer :crediting_book_transaction_id
      integer :refunded_funding_transaction_id
      text :strategy_name
      text :classification
    end
  end
end
