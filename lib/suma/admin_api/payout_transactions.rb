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
      self,
      Suma::Payment::PayoutTransaction,
      DetailedPayoutTransactionEntity,
    )

    params do
      requires :amount, allow_blank: false, type: JSON do
        use :money
      end
      requires :stripe_charge_id, type: String, allow_blank: false
    end
    post :stripe_refund do
      check_role_access!(admin_member, :write, :admin_payments)
      funding_strategy = Suma::Payment::FundingTransaction::StripeCardStrategy.
        where(Sequel.pg_jsonb_op(:charge_json).get_text("id") => params[:stripe_charge_id]).
        first
      funding_strategy or forbidden!
      begin
        px = Suma::Payment::PayoutTransaction.initiate_refund(
          funding_strategy.funding_transaction,
          amount: params[:amount],
          stripe_charge_id: params[:stripe_charge_id],
          apply_at: Time.now,
          apply_credit: true,
        )
      rescue Suma::Payment::Invalid => e
        adminerror!(409, e.message, code: "invalid_payout_instrument")
      end
      created_resource_headers(px.id, px.admin_link)
      status 200
      present px, with: DetailedPayoutTransactionEntity
    end
  end
end
