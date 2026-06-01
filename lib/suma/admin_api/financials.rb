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

  class OffPlatformTransactionEntity < BaseModelEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase

    model Suma::Payment::OffPlatformStrategy
    expose :amount, with: MoneyEntity
    expose :transacted_at, &self.delegate_to(:strategy, :transacted_at)
    expose :note, &self.delegate_to(:strategy, :note)
    expose :check_or_transaction_number, &self.delegate_to(:strategy, :check_or_transaction_number)
  end

  class PlatformStatusEntity < BaseModelEntity
    include Suma::AdminAPI::Entities

    model Suma::Payment::PlatformStatus::Calculated
    expose :funding, with: MoneyEntity
    expose :funding_count
    expose :payouts, with: MoneyEntity
    expose :payout_count
    expose :refunds, with: MoneyEntity
    expose :refund_count
    expose :member_liabilities, with: MoneyEntity
    expose :assets, with: MoneyEntity
    expose_related :platform_ledgers, with: LedgerEntity
    expose_related :unbalanced_ledgers, with: LedgerEntity
    expose_related :off_platform_funding_transactions, with: OffPlatformTransactionEntity
    expose_related :off_platform_payout_transactions, with: OffPlatformTransactionEntity
  end

  resource :financials do
    resource :platform_status do
      get do
        check_admin_role_access!(:read, :admin_payments)
        res = Suma::Payment::PlatformStatus::Calculated.new
        present res, with: PlatformStatusEntity
      end

      Suma::AdminAPI::CommonEndpoints.related_children(self, PlatformStatusEntity)
    end
  end
end
