# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:payment_funding_transactions) do
      add_column :reversal_book_transaction_id, :payment_book_transactions, index: true
    end

    create_table(:mobility_vendor_adapters) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      timestamptz :updated_at

      boolean :uses_deep_linking, null: false, default: false
      foreign_key :deeplink_vendor_id, :vendors, null: false, index: true
      text :trip_manager_key, null: false, default: ""

      boolean :send_receipts, null: false, default: false

      constraint(
        :deeplink_cohesion,
        (Sequel[:uses_deep_linking] & (Sequel[:deeplink_vendor_id] !~ nil)) |
        (!Sequel[:uses_deep_linking] & Sequel[:trip_manager_key] !~ '')
      )
    end
  end
end
