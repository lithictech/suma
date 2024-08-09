# frozen_string_literal: true

require "suma/payment/ledgers_view"
require "suma/api"

class Suma::API::Ledgers < Suma::API::V1
  include Suma::API::Entities

  resource :ledgers do
    desc "Return an overview of cash ledger and ledgers with transactions including balances, and recent transactions."
    get :overview do
      me = current_member
      ledgers = (me.payment_account&.ledgers || []).select do |led|
        led.any_transactions? || led.vendor_service_categories.first&.slug === "cash"
      end
      lv = Suma::Payment::LedgersView.new(ledgers, member: me)
      present(
        lv,
        with: LedgersViewEntity,
        first_page_count: 0,
      )
    end

    route_param :id, type: Integer do
      desc "Return a page of ledger lines."
      params do
        use :short_pagination
      end
      get :lines do
        me = current_member
        me.payment_account or forbidden!
        (ledger = me.payment_account.ledgers_dataset[params[:id]]) or forbidden!
        ds = ledger.combined_book_transactions_dataset
        ds = paginate(ds, params)
        present_collection ds, with: LedgerLinesEntity, ledger:
      end
    end
  end

  class LedgerLinesEntity < Suma::Service::Collection::BaseEntity
    include Suma::API::Entities
    expose :items, with: LedgerLineEntity
    expose :ledger_id do |_, opts|
      opts.fetch(:ledger).id
    end
  end

  class LedgersViewEntity < BaseEntity
    include Suma::API::Entities
    expose :total_balance, with: MoneyEntity
    expose :lifetime_savings, with: MoneyEntity
    expose :ledgers, with: LedgerEntity
    expose :recent_lines, with: LedgerLineEntity
  end
end
