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
      present(lv, with: LedgersViewEntity)
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

  class LedgerLineUsageDetailsEntity < Grape::Entity
    expose :code
    expose :args, documentation: {type: Suma::Service::Entities::RecordString}
  end

  module LedgerLineAmountMixin
    def xyz; end

    def self.included(ctx)
      ctx.expose :amount, with: Suma::API::Entities::MoneyEntity do |inst, opts|
        if inst.directed?
          inst.amount
        elsif (ledger = opts[:ledger])
          inst.receiving_ledger === ledger ? inst.amount : (inst.amount * -1)
        else
          raise "Must use directed ledger lines or pass :ledger option"
        end
      end
    end
  end

  class LedgerLineEntity < BaseEntity
    expose :id
    expose :ledger_id do |inst, opts|
      # Can be taken from the directed book transaction in a recent line,
      # or the explicit ledger in the ledger lines.
      inst.respond_to?(:ledger) ? inst.ledger.id : opts.fetch(:ledger).id
    end
    expose :opaque_id, documentation: {type: String}
    expose :apply_at, as: :at
    expose_translated :memo
    include LedgerLineAmountMixin

    expose_array :usage_details, LedgerLineUsageDetailsEntity
  end

  class LedgerEntity < BaseEntity
    include Suma::API::Entities

    expose :id
    expose :name
    expose_translated :contribution_text
    expose :balance, with: MoneyEntity
  end

  class LedgerLinesEntity < Suma::Service::Collection::BaseEntity
    include Suma::API::Entities

    expose_array :items, LedgerLineEntity
    expose(:ledger_id) { |_, opts| opts.fetch(:ledger).id }
  end

  class LedgersViewEntity < BaseEntity
    include Suma::API::Entities

    expose :total_balance, with: MoneyEntity
    expose :lifetime_savings, with: MoneyEntity
    expose_array :ledgers, LedgerEntity
    expose_array :recent_lines, LedgerLineEntity
  end
end
