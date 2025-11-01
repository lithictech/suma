# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::BookTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedBookTransactionEntity < BookTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :opaque_id
    expose :memo, with: TranslatedTextEntity
    expose :originating_funding_transaction, with: FundingTransactionEntity
    expose :originating_payout_transaction, with: PayoutTransactionEntity
    expose :credited_payout_transaction, with: PayoutTransactionEntity
    expose :charge_contributed_to, with: ChargeEntity
    expose :triggered_by,
           with: PaymentTriggerEntity,
           &self.delegate_to(:triggered_by, :trigger, safe: true)
  end

  resource :book_transactions do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Payment::BookTransaction,
      BookTransactionEntity,
    )

    params do
      requires :originating_ledger_id, type: Integer
      requires :receiving_ledger_id, type: Integer
      requires :memo, type: JSON
      requires :vendor_service_category_slug, type: String
      requires :amount, allow_blank: false, type: JSON do
        use :money
      end
    end
    post :create do
      check_admin_role_access!(:write, Suma::Payment::Ledger)
      (originating = Suma::Payment::Ledger[params[:originating_ledger_id]]) or forbidden!
      (receiving = Suma::Payment::Ledger[params[:receiving_ledger_id]]) or forbidden!
      (vsc = Suma::Vendor::ServiceCategory[slug: params[:vendor_service_category_slug]]) or forbidden!
      bx = Suma::Payment::BookTransaction.create(
        apply_at: Time.now,
        amount: params[:amount],
        originating_ledger: originating,
        receiving_ledger: receiving,
        associated_vendor_service_category: vsc,
        memo: Suma::TranslatedText.find_or_create(**params[:memo]),
      )
      created_resource_headers(bx.id, bx.admin_link)
      status 200
      present bx, with: DetailedBookTransactionEntity
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Payment::BookTransaction,
      DetailedBookTransactionEntity,
    )
  end
end
