# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::PayoutTransaction < Suma::Analytics::Model(Sequel[:analytics][:payout_transactions])
  unique_key :payout_transaction_id

  destroy_from Suma::Payment::PayoutTransaction

  denormalize Suma::Payment::PayoutTransaction, with: [
    [:payout_transaction_id, :id],
    :created_at,
    :updated_at,
    :status,
    :amount,
    :memo,
    :originating_payment_account_id,
    [:originating_member_id, [:originating_payment_account, :member_id]],
    :platform_ledger_id,
    :originated_book_transaction_id,
    :crediting_book_transaction_id,
    :refunded_funding_transaction_id,
    [:strategy_name, [:strategy, :short_name]],
    :classification,
  ]
end
