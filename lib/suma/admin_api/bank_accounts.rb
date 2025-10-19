# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::BankAccounts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class BankAccountEntity < PaymentInstrumentEntity
    expose :verified_at
    expose :routing_number
    expose :masked_account_number
    expose :account_type
  end

  class DetailedBankAccountEntity < BankAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :member, with: MemberEntity
  end

  resource :bank_accounts do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::BankAccount,
      BankAccountEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::BankAccount,
      DetailedBankAccountEntity,
    )
  end
end
