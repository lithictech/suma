# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Search < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :search do
    resource :ledgers do
      params do
        optional :q, type: String
      end
      post do
        ds = Suma::Payment::Ledger.dataset
        if (q = params[:q]).present?
          conds = search_to_sql(q, :name) |
            Sequel[account: Suma::Payment::Account.where(
              Sequel[member: Suma::Member.where(search_to_sql(q, :name))] |
                Sequel[vendor: Suma::Vendor.where(search_to_sql(q, :name))],
            )]
          ds = ds.where(conds)
        end
        ds = ds.order(:name).limit(15)
        status 200
        present_collection ds, with: SearchLedgerEntity
      end

      params do
        optional :ids, type: Array[Integer]
        optional :platform_categories, type: Array[String]
      end
      post :lookup do
        by_id = {}
        params.fetch(:ids, []).each do |ledger_id|
          led = Suma::Payment::Ledger[ledger_id]
          by_id[led.id.to_s] = led if led
        end
        platform_by_category = {}
        platform = Suma::Payment::Account.lookup_platform_account
        params.fetch(:platform_categories, []).each do |slug|
          led = platform.ledgers_dataset[vendor_service_categories: Suma::Vendor::ServiceCategory.where(slug:)]
          platform_by_category[slug] = led if led
        end
        result = {
          by_id: by_id.transform_values { |v| SearchLedgerEntity.represent(v) },
          platform_by_category: platform_by_category.transform_values { |v| SearchLedgerEntity.represent(v) },
        }
        status 200
        present result
      end
    end

    params do
      optional :q, type: String
      optional :payment_method_type, type: String, values: ["bank_account"]
    end
    post :payment_instruments do
      ds = Suma::Payment::BankAccount.dataset.usable.verified
      if (q = params[:q]).present?
        conds = search_to_sql(q, :name) |
          Sequel[legal_entity: Suma::LegalEntity.where(
            search_to_sql(q, :name) |
            Sequel[member: Suma::Member.where(search_to_sql(q, :name))],
          )]
        ds = ds.where(conds)
      end
      ds = ds.order(:name).limit(15)
      status 200
      present_collection ds, with: SearchPaymentInstrumentEntity
    end
  end

  class SearchLedgerEntity < BaseEntity
    expose :key do |inst|
      inst.id.to_s
    end
    expose :id
    expose :admin_link
    expose :search_label, as: :label
  end

  class SearchPaymentInstrumentEntity < BaseEntity
    expose :key do |inst|
      "#{inst.id}-#{inst.payment_method_type}"
    end
    expose :id
    expose :payment_method_type
    expose :admin_link
    expose :search_label, as: :label
  end
end
