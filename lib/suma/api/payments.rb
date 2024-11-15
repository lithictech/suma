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
      instrument = find_payment_instrument!(c, params)
      fx = Suma::Payment::FundingTransaction.start_and_transfer(
        c,
        amount: params[:amount],
        instrument:,
        apply_at: current_time,
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
    expose_translated :memo
  end
end
