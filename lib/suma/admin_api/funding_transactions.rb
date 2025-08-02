# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::FundingTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedFundingTransactionEntity < FundingTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose_translated :memo
    expose :can_refund?, as: :can_refund
    expose :refundable_amount, with: MoneyEntity
    expose :refunded_amount, with: MoneyEntity
    expose :refund_payout_transactions, with: PayoutTransactionEntity
    expose :platform_ledger, with: SimpleLedgerEntity
    expose :originated_book_transaction, with: BookTransactionEntity
    expose :audit_activities, with: ActivityEntity
    expose :audit_logs, with: AuditLogEntity
  end

  resource :funding_transactions do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::FundingTransaction,
      FundingTransactionEntity,
    )

    desc "Create a funding transaction and book transfer for the given instrument and its owner's cash ledger."
    params do
      use :payment_instrument
      requires(:amount, allow_blank: false, type: JSON) { use :money }
    end
    post :create_for_self do
      check_admin_role_access!(:write, Suma::Payment::FundingTransaction)
      instrument_ds = case params[:payment_method_type]
        when "bank_account"
          Suma::Payment::BankAccount.dataset
        when "card"
          Suma::Payment::Card.dataset
        else
          raise "Invalid payment_method_type"
      end
      (instrument = instrument_ds[params[:payment_instrument_id]]) or forbidden!
      c = instrument.member
      begin
        fx = Suma::Payment::FundingTransaction.start_and_transfer(
          c,
          amount: params[:amount],
          instrument:,
          apply_at: Time.now,
        )
      rescue Suma::Payment::Invalid => e
        merror!(409, e.message, code: "invalid_funding_instrument", skip_loc_check: true)
      end
      created_resource_headers(fx.id, fx.admin_link)
      status 200
      present fx, with: DetailedFundingTransactionEntity
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::FundingTransaction,
      DetailedFundingTransactionEntity,
    )

    route_param :id, type: Integer do
      params do
        optional(:amount, allow_blank: false, type: JSON) { use :money }
        optional :full, allow_blank: false, type: Boolean
        exactly_one_of :amount, :full
      end
      post :refund do
        check_admin_role_access!(:write, Suma::Payment::PayoutTransaction)
        Suma::Payment::PayoutTransaction.db.transaction do
          (fx = Suma::Payment::FundingTransaction[params[:id]]) or forbidden!
          amount = params[:full] ? fx.refundable_amount : Suma::Moneyutil.from_h(params[:amount])
          begin
            px = Suma::Payment::PayoutTransaction.initiate_refund(
              fx,
              amount:,
              apply_at: Time.now,
              strategy: :infer,
              apply_credit: :infer,
            )
          rescue Suma::Payment::PayoutTransaction::InvalidAmount => e
            invalid!(e.to_s)
          end
          created_resource_headers(px.id, px.admin_link)
          status 200
          present px, with: PayoutTransactionEntity
        end
      end
    end
  end
end
