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

    get :vendor_service_categories do
      sc = Suma::Vendor::ServiceCategory.dataset.order(:name).all
      present_collection sc, with: HierarchicalCategoryEntity
    end

    get :eligibility_constraints do
      ec = Suma::Eligibility::Constraint.dataset.order(:name).all
      present({items: ec, statuses: Suma::Eligibility::Constraint::STATUSES},
              with: EligibilityConstraintCollectionEntity,)
    end
  end

  class CurrencyEntity < BaseEntity
    expose :symbol
    expose :code
  end

  class HierarchicalCategoryEntity < BaseEntity
    expose :id
    expose :slug
    expose :name
    expose :full_label, as: :label
  end

  class EligibilityConstraintCollectionEntity < BaseEntity
    expose :items, with: Suma::AdminAPI::Entities::EligibilityConstraintEntity
    expose :statuses
  end
end
