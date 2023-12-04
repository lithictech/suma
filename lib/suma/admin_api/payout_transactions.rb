# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PayoutTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedPayoutTransactionEntity < PayoutTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose_translated :memo
    expose :platform_ledger, with: SimpleLedgerEntity
    expose :crediting_book_transaction, with: BookTransactionEntity
    expose :originated_book_transaction, with: BookTransactionEntity
    expose :audit_logs, with: AuditLogEntity
  end

  resource :payout_transactions do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::PayoutTransaction,
      PayoutTransactionEntity,
      translation_search_params: [:memo],
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self, Suma::Payment::PayoutTransaction, DetailedPayoutTransactionEntity,
    )
  end
end
