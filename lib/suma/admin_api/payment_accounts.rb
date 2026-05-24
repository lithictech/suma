# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::PaymentAccounts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class PaymentAccountEntity < SimplePaymentAccountEntity
    include Suma::AdminAPI::Entities

    expose :member, with: MemberEntity
    expose :vendor, with: VendorEntity
    expose :is_platform_account
  end

  class LedgerEntity < SimpleLedgerEntity
    include Suma::AdminAPI::Entities

    expose :balance, with: MoneyEntity
  end

  class DetailedPaymentAccountEntity < PaymentAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose_related :ledgers, with: LedgerEntity
    expose :total_balance, with: MoneyEntity
    expose_related :ledgers, with: LedgerEntity
    expose_related :originated_funding_transactions, with: FundingTransactionEntity
    expose_related :originated_payout_transactions, with: PayoutTransactionEntity
  end

  resource :payment_accounts do
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::Account,
      DetailedPaymentAccountEntity,
    )
  end
end
