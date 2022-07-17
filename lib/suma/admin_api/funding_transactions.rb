# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Payments < Suma::AdminAPI::V1
  resource :payments do
    resource :book_transactions do
      params do
        use :pagination
        use :ordering, model: Suma::Member
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
        present_collection ds, with: Suma::AdminAPI::BookTransactionEntity
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
          present o, with: Suma::AdminAPI::DetailedBookTransactionEntity
        end
      end
    end

    resource :funding_transactions do
      params do
        use :pagination
        use :ordering, model: Suma::Member
        use :searchable
      end
      get do
        ds = Suma::Payment::FundingTransaction.dataset
        if (memo_like = search_param_to_sql(params, :memo))
          ds = ds.where(memo_like)
        end
        ds = order(ds, params)
        ds = paginate(ds, params)
        present_collection ds, with: Suma::AdminAPI::FundingTransactionEntity
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
          present o, with: Suma::AdminAPI::DetailedFundingTransactionEntity
        end
      end
    end
  end
end
