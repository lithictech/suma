# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PaymentLedgers < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class LedgerEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :name
    expose :admin_label
    expose :is_platform_account, &self.delegate_to(:account, :is_platform_account)
    expose :currency
    expose :balance, with: MoneyEntity
    expose :member, with: MemberEntity, &self.delegate_to(:account, :member)
  end

  class DetailedLedgerEntity < LedgerEntity
    include AutoExposeDetail
    expose :vendor_service_categories, with: VendorServiceCategoryEntity
    expose :combined_book_transactions, with: BookTransactionEntity
  end

  resource :payment_ledgers do
    params do
      use :pagination
      use :ordering, model: Suma::Payment::Ledger, default: nil
      use :searchable
    end
    get do
      check_role_access!(admin_member, :read, :admin_payments)
      ds = Suma::Payment::Ledger.dataset
      if (search_expr = search_param_to_sql(params, :name))
        ds = ds.where(search_expr)
      end
      if params[:order_by]
        ds = order(ds, params)
      else
        # Default ordering is to put platform accounts first, then order by created at,
        # since we likely only have a few platform accounts.
        # We need to join with payment accounts,
        # then unselect the addition columns via select_all when reselecting the model.
        params[:order_by] = [:is_platform_account, Sequel[:payment_ledgers][:created_at]]
        ds = ds.join(:payment_accounts, {id: :account_id})
        ds = order(ds, params, disambiguator: Sequel[:payment_ledgers][:id])
        ds = ds.select_all(:payment_ledgers)
      end
      ds = paginate(ds, params)

      status 200
      present_collection ds, with: LedgerEntity
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::Ledger,
      DetailedLedgerEntity,
    )
  end
end
