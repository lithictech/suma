# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::Meta < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :meta do
    get :currencies do
      use_http_expires_caching 2.days
      cur = Suma::SupportedCurrency.dataset.order(:ordinal).all
      present_collection cur, with: CurrencyEntity
    end

    get :geographies do
      use_http_expires_caching 2.days
      countries = Suma::SupportedGeography.order(:label).where(type: "country").all
      provinces = Suma::SupportedGeography.order(:label).where(type: "province").all
      result = {}
      result[:countries] = countries.map do |c|
        {label: c.label, value: c.value}
      end
      result[:provinces] = provinces.map do |p|
        {label: p.label, value: p.value, country: {label: p.parent.label, value: p.parent.value}}
      end
      present result
    end

    get :vendors do
      use_http_expires_caching 12.hours
      v = Suma::Vendor.dataset.order(:name).all
      present_collection v, with: VendorCollectionEntity
    end

    get :vendor_service_categories do
      use_http_expires_caching 12.hours
      sc = Suma::Vendor::ServiceCategory.dataset.order(:name).all
      present_collection sc, with: HierarchicalCategoryEntity
    end

    get :eligibility_constraints do
      use_http_expires_caching 12.hours
      ec = Suma::Eligibility::Constraint.dataset.order(:name).all
      present({items: ec, statuses: Suma::Eligibility::Constraint::STATUSES},
              with: EligibilityConstraintCollectionEntity,)
    end
  end

  class CurrencyEntity < BaseEntity
    expose :symbol
    expose :code
  end

  class VendorCollectionEntity < BaseEntity
    expose :name
  end

  class HierarchicalCategoryEntity < BaseEntity
    expose :slug
    expose :name
    expose :full_label, as: :label
  end

  class EligibilityConstraintCollectionEntity < BaseEntity
    expose :items, with: Suma::AdminAPI::Entities::EligibilityConstraintEntity
    expose :statuses
  end
end
