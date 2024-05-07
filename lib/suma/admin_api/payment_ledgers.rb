# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::PaymentLedgers < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :payment_ledgers do
    resource :platform_ledgers do
      get do
        platform_ledgers_ds = Suma::Payment::Account.lookup_platform_account.ledgers_dataset
        status 200
        present_collection platform_ledgers_ds, with: PaymentAccountLedgerEntity
      end

      route_param :id, type: Integer do
        get do
          pa = Suma::Payment::Account.lookup_platform_account
          (found_platform_ledger = pa.ledgers_dataset[params[:id]]) or forbidden!

          status 200
          present found_platform_ledger, with: DetailedPaymentAccountLedgerEntity
        end
      end
    end
  end
end
