# frozen_string_literal: true

require "grape"

require "suma/api"

class Suma::API::Payments < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  resource :payments do
    params do
      requires :amount, allow_blank: false, type: JSON do
        use :funding_money
      end
      use :payment_instrument
    end
    post :create_funding do
      c = current_member
      Suma::Payment.ensure_cash_ledger(c)
      bank_account = c.usable_payment_instruments.find do |pi|
        pi.id == params[:payment_instrument_id] && pi.payment_method_type == params[:payment_method_type]
      end
      merror!(403, "Bank account not found", code: "resource_not_found") unless bank_account
      fx = Suma::Payment::FundingTransaction.start_and_transfer(
        Suma::Payment.ensure_cash_ledger(c),
        amount: params[:amount],
        bank_account:,
        vendor_service_category: Suma::Vendor::ServiceCategory.find_or_create(name: "Cash"),
      )
      add_current_member_header
      status 200
      present fx, with: FundingTransactionEntity
    end
  end

  class FundingTransactionEntity < BaseEntity
    include Suma::API::Entities
    expose :id
    expose :created_at
    expose :status
    expose :amount, with: MoneyEntity
    expose :memo
  end
end
