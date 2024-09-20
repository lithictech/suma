# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::FundingTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedFundingTransactionEntity < FundingTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose_translated :memo
    expose :platform_ledger, with: SimpleLedgerEntity
    expose :originated_book_transaction, with: BookTransactionEntity
    expose :audit_logs, with: AuditLogEntity
  end

  resource :funding_transactions do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::FundingTransaction,
      FundingTransactionEntity,
      translation_search_params: [:memo],
    )

    desc "Create a funding transaction and book transfer for the given instrument and its owner's cash ledger."
    params do
      use :payment_instrument
      requires(:amount, allow_blank: false, type: JSON) { use :money }
    end
    post :create_for_self do
      check_role_access!(admin_member, :write, :admin_payments)
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
  end
end
