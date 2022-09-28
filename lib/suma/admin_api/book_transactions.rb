# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::BookTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :book_transactions do
    params do
      use :pagination
      use :ordering, model: Suma::Payment::BookTransaction
      use :searchable
    end
    get do
      ds = Suma::Payment::BookTransaction.dataset
      if (opaque_id_like = search_param_to_sql(params, :opaque_id))
        memo_like = search_param_to_sql(params, :memo)
        ds = ds.where(memo_like | opaque_id_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: BookTransactionEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_book_transaction!
          (o = Suma::Payment::BookTransaction[params[:id]]) or forbidden!
          return o
        end
      end

      get do
        o = lookup_book_transaction!
        present o, with: DetailedBookTransactionEntity
      end
    end
  end

  class DetailedBookTransactionEntity < BookTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :opaque_id
    expose :memo
    expose :funding_transactions, with: FundingTransactionEntity
    expose :charges, with: ChargeEntity
  end
end
