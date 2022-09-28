# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::FundingTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :funding_transactions do
    params do
      use :pagination
      use :ordering, model: Suma::Payment::FundingTransaction
      use :searchable
    end
    get do
      ds = Suma::Payment::FundingTransaction.dataset
      if (memo_like = search_param_to_sql(params, :memo))
        ds = ds.where(memo_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: FundingTransactionEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_funding_transaction!
          (o = Suma::Payment::FundingTransaction[params[:id]]) or forbidden!
          return o
        end
      end

      get do
        o = lookup_funding_transaction!
        present o, with: DetailedFundingTransactionEntity
      end
    end
  end

  class DetailedFundingTransactionEntity < FundingTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :memo
    expose :platform_ledger, with: SimpleLedgerEntity
    expose :originated_book_transaction, with: BookTransactionEntity
    expose :audit_logs, with: AuditLogEntity
  end
end
