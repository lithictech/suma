# frozen_string_literal: true

require "suma/admin_api"
require "suma/payment/platform_status"

class Suma::AdminAPI::Financials < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class LedgerEntity < SimpleLedgerEntity
    include Suma::AdminAPI::Entities
    expose :balance, with: MoneyEntity
    expose :total_credits, with: MoneyEntity
    expose :count_credits
    expose :total_debits, with: MoneyEntity
    expose :count_debits
  end

  class PlatformStatusEntity < BaseEntity
    include Suma::AdminAPI::Entities

    expose :funding, with: MoneyEntity
    expose :funding_count
    expose :payouts, with: MoneyEntity
    expose :payout_count
    expose :refunds, with: MoneyEntity
    expose :refund_count
    expose :member_liabilities, with: MoneyEntity
    expose :assets, with: MoneyEntity
    expose :platform_ledgers, with: LedgerEntity
    expose :unbalanced_ledgers, with: LedgerEntity
  end

  resource :financials do
    get :platform_status do
      check_admin_role_access!(:read, :admin_payments)
      res = Suma::Payment::PlatformStatus.new.calculate
      present res, with: PlatformStatusEntity
    end
  end
end
