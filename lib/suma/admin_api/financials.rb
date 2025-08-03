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
    expose :total_debits, with: MoneyEntity
  end

  class PlatformStatusEntity < BaseEntity
    include Suma::AdminAPI::Entities

    expose :funding, with: MoneyEntity
    expose :payouts, with: MoneyEntity
    expose :refunds, with: MoneyEntity
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
