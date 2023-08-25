# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PayoutTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :payout_transactions do
    params do
      use :pagination
      use :ordering, model: Suma::Payment::PayoutTransaction
      use :searchable
    end
    get do
      ds = Suma::Payment::PayoutTransaction.dataset
      if (memoen_like = search_param_to_sql(params, :memo_en))
        memoes_like = search_param_to_sql(params, :memo_es)
        ds = ds.translation_join(:memo, [:en, :es]).where(memoen_like | memoes_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: PayoutTransactionEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_payout_transaction!
          (o = Suma::Payment::PayoutTransaction[params[:id]]) or forbidden!
          return o
        end
      end

      get do
        o = lookup_payout_transaction!
        present o, with: DetailedPayoutTransactionEntity
      end
    end
  end

  class DetailedPayoutTransactionEntity < PayoutTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose_translated :memo
    expose :platform_ledger, with: SimpleLedgerEntity
    expose :crediting_book_transaction, with: BookTransactionEntity
    expose :originated_book_transaction, with: BookTransactionEntity
    expose :audit_logs, with: AuditLogEntity
  end
end
