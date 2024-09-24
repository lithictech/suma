# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::BookTransaction < Suma::Analytics::Model(Sequel[:analytics][:book_transactions])
  unique_key :book_transaction_id

  destroy_from Suma::Payment::BookTransaction

  denormalize Suma::Payment::BookTransaction, with: [
    [:book_transaction_id, :id],
    :created_at,
    :apply_at,
    :opaque_id,
    :originating_ledger_id,
    [:originating_member_id, [:originating_ledger, :account, :member_id]],
    :receiving_ledger_id,
    [:receiving_member_id, [:receiving_ledger, :account, :member_id]],
    [:category_id, :associated_vendor_service_category_id],
    [:category_name, [:associated_vendor_service_category, :name]],
    :amount,
    :memo,
    [:usage_codes, ->(m) { m.usage_details.map(&:code) }],
    [:is_cash, ->(m) { m.associated_vendor_service_category === Suma::Vendor::ServiceCategory.cash }],
    [:platform_originating, ->(m) { m.originating_ledger.account.platform_account? }],
    [:platform_receiving, ->(m) { m.receiving_ledger.account.platform_account? }],
  ]
end
