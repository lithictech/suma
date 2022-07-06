# frozen_string_literal: true

require "suma/payment/ledgers_view"
require "suma/api"

class Suma::API::Ledgers < Suma::API::V1
  include Suma::API::Entities

  resource :ledgers do
    desc "Return an overview of all ledgers including balances, and recent transactions."
    get :overview do
      me = current_member
      lv = Suma::Payment::LedgersView.new(me.payment_account&.ledgers || [])
      first_page = []
      page_count = 0
      if lv.ledgers.length == 1
        first_page = lv.ledgers.first.combined_book_transactions_dataset
        first_page = paginate(first_page, {page: 1, per_page: Suma::Service::SHORT_PAGE_SIZE})
        page_count = first_page.page_count
        first_page = first_page.all.map { |led| led.directed(lv.ledgers.first) }
      end
      present(
        lv,
        with: LedgersViewEntity,
        single_ledger_lines_first_page: first_page,
        single_ledger_page_count: page_count,
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
        present_collection ds, with: LedgerLineEntity, ledger:
      end
    end
  end

  class LedgersViewEntity < BaseEntity
    include Suma::API::Entities
    expose :total_balance, with: MoneyEntity
    expose :ledgers, with: LedgerEntity
    expose :single_ledger_lines_first_page, with: LedgerLineEntity do |_, opts|
      opts.fetch(:single_ledger_lines_first_page)
    end
    expose :single_ledger_page_count do |_, opts|
      opts.fetch(:single_ledger_page_count)
    end
  end
end
