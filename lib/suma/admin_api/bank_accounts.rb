# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::BankAccounts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :bank_accounts do
    route_param :id, type: Integer do
      helpers do
        def lookup
          (o = Suma::BankAccount[params[:id]]) or forbidden!
          return o
        end
      end

      get do
        o = lookup
        present o, with: DetailedBankAccountEntity
      end

      delete do
        o = lookup
        o.db.transaction do
          o.soft_delete
        end
        present o, with: DetailedBankAccountEntity
      end

      params do
        optional :verified, type: Boolean
      end
      patch do
        o = lookup
        o.db.transaction do
          set_declared(o, params)
          save_or_error!(o)
        end
        status 200
        present o, with: DetailedBankAccountEntity
      end
    end
  end

  class DetailedBankAccountEntity < BankAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :member, with: MemberEntity
  end
end
