# frozen_string_literal: true

require "sequel/all_or_none_constraint"

Sequel.migration do
  up do
    alter_table(:payment_funding_transactions) do
      add_foreign_key :reversal_book_transaction_id, :payment_book_transactions, unique: true
    end
    alter_table(:payment_payout_transactions) do
      add_foreign_key :reversal_book_transaction_id, :payment_book_transactions, unique: true
      drop_constraint(:refund_fields_valid)
      add_constraint(
        :refund_fields_valid,
        Sequel.all_or_none_constraint([:refunded_funding_transaction_id, :crediting_book_transaction_id]),
      )
    end
  end
  down do
    alter_table(:payment_funding_transactions) do
      drop :reversal_book_transaction_id
    end
    alter_table(:payment_payout_transactions) do
      drop :reversal_book_transaction_id
    end
  end
end
