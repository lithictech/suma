# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::BankAccounts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedBankAccountEntity < BankAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :member, with: MemberEntity
  end

  resource :bank_accounts do
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::BankAccount,
      DetailedBankAccountEntity,
    )
  end
end
