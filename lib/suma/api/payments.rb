# frozen_string_literal: true

require "grape"

require "suma/api"

class Suma::API::Payments < Suma::API::V1
  include Suma::Service::Types

  resource :payments do
    params do
      requires :amount, type: JSON do
        use :money
      end
      requires :payment_method_type, type: String, values: ["bank_account"]
      requires :payment_method_id, type: Integer
    end
    post :create_funding do
      c = current_member
      Suma::Payment.ensure_cash_ledger(c)
      bank_account = c.usable_payment_instruments.find do |pi|
        pi.id == params[:payment_method_id] && pi.payment_method_type == params[:payment_method_type]
      end
      merror!(403, "Bank account not found", code: "resource_not_found") unless bank_account
      fx = c.db.transaction do
        now = Time.now
        fx = Suma::Payment::FundingTransaction.start_new(c.payment_account, amount: params[:amount], bank_account:)
        # TODO: Move this to the model layer and test it thoroughly,
        # it is too important to just have testing as a side effect in the endpoint.
        originated_book_transaction = Suma::Payment::BookTransaction.create(
          apply_at: now,
          amount: fx.amount,
          originating_ledger: fx.platform_ledger,
          receiving_ledger: Suma::Payment.ensure_cash_ledger(c),
          associated_vendor_service_category: Suma::Vendor::ServiceCategory.find_or_create(name: "Cash"),
          memo: fx.memo,
        )
        fx.update(originated_book_transaction:)
        fx
      end
      status 200
      present fx, with: Suma::API::FundingTransactionEntity
    end
  end
end
