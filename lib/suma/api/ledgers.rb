# frozen_string_literal: true

require "suma/payment/ledgers_view"
require "suma/api"

class Suma::API::Ledgers < Suma::API::V1
  include Suma::API::Entities

  resource :ledgers do
    desc "Return an overview of cash ledger and ledgers with transactions including balances, and recent transactions."
    get :overview do
      me = current_member
      ledgers = (me.payment_account&.ledgers || []).select { |led| led.any_transactions? || led.name === "Cash" }
      lv = Suma::Payment::LedgersView.new(ledgers)
      first_page = []
      page_count = 0
      if (first_ledger = lv.ledgers.first)
        first_page = first_ledger.combined_book_transactions_dataset
        first_page = paginate(first_page, {page: 1, per_page: Suma::Service::SHORT_PAGE_SIZE})
        page_count = first_page.page_count
        first_page = first_page.all.map { |led| led.directed(first_ledger) }
      end
      present(
        lv,
        with: LedgersViewEntity,
        first_ledger_lines_first_page: first_page,
        first_ledger_page_count: page_count,
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
    expose :ledgers, with: LedgerEntity
    expose :first_ledger_lines_first_page, with: LedgerLineEntity do |_, opts|
      opts.fetch(:first_ledger_lines_first_page)
    end
    expose :first_ledger_page_count do |_, opts|
      opts.fetch(:first_ledger_page_count)
    end
  end
end
