# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::FundingTransaction < Suma::Analytics::Model(Sequel[:analytics][:funding_transactions])
  unique_key :funding_transaction_id

  destroy_from Suma::Payment::FundingTransaction

  denormalize Suma::Payment::FundingTransaction, with: [
    [:funding_transaction_id, :id],
    :created_at,
    :updated_at,
    :status,
    :amount,
    :memo,
    :originating_payment_account_id,
    [:originating_member_id, [:originating_payment_account, :member_id]],
    :platform_ledger_id,
    :originated_book_transaction_id,
    [:usage_codes, ->(m) { m.originated_book_transaction.usage_details.map(&:code).sort }],
    [:strategy_name, [:strategy, :short_name]],
  ]
end
