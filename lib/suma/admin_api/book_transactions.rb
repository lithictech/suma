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
        ds = ds.translation_join(:memo, [:en, :es]).where(
          search_param_to_sql(params, :memo_en) |
            search_param_to_sql(params, :memo_es) |
            opaque_id_like,
        )
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: BookTransactionEntity
    end

    params do
      requires :originating_ledger_id, type: Integer
      requires :receiving_ledger_id, type: Integer
      requires :memo, type: String
      requires :vendor_service_category_slug, type: String
      requires :amount, allow_blank: false, type: JSON do
        use :money
      end
    end
    post :create do
      (originating = Suma::Payment::Ledger[params[:originating_ledger_id]]) or forbidden!
      (receiving = Suma::Payment::Ledger[params[:receiving_ledger_id]]) or forbidden!
      (vsc = Suma::Vendor::ServiceCategory[slug: params[:vendor_service_category_slug]]) or forbidden!
      bx = Suma::Payment::BookTransaction.create(
        apply_at: Time.now,
        amount: params[:amount],
        originating_ledger: originating,
        receiving_ledger: receiving,
        associated_vendor_service_category: vsc,
        memo: Suma::TranslatedText.create(all: params[:memo]),
      )
      created_resource_headers(bx.id, bx.admin_link)
      status 200
      present bx, with: DetailedBookTransactionEntity
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
    expose_translated :memo
    expose :funding_transactions, with: FundingTransactionEntity
    expose :charges, with: ChargeEntity
  end
end
