# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PaymentLedgers < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :payment_ledgers do
    helpers do
      def search_order_paginate(ds, params)
        if (name_like = search_param_to_sql(params, :name))
          ds = ds.where(name_like)
        end
        ds = order(ds, params)
        return paginate(ds, params)
      end
    end

    params do
      use :pagination
      use :ordering, model: Suma::Payment::Ledger
      use :searchable
    end
    get do
      platform_ledgers_ds = Suma::Payment::Account.lookup_platform_account.ledgers_dataset
      platform_ledgers_ds = search_order_paginate(platform_ledgers_ds, params)

      ledgers_ds = Suma::Payment::Ledger.exclude(id: platform_ledgers_ds.select(:id))
      ledgers_ds = search_order_paginate(ledgers_ds, params)

      # List platform ledgers first
      ledgers = platform_ledgers_ds.all + ledgers_ds.all

      status 200
      present_collection ledgers, with: PaymentAccountLedgerEntity
    end

    route_param :id, type: Integer do
      get do
        (led = Suma::Payment::Ledger[params[:id]]) or forbidden!
        status 200
        present led, with: DetailedPaymentAccountLedgerEntity
      end
    end
  end
end
