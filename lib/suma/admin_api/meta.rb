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

    get :vendor_service_categories do
      use_http_expires_caching 12.hours
      sc = Suma::Vendor::ServiceCategory.dataset.order(:name).all
      present_collection sc, with: HierarchicalCategoryEntity
    end

    get :eligibility_constraints do
      use_http_expires_caching 12.hours
      ec = Suma::Eligibility::Constraint.dataset.order(:id).all
      present_collection ec, with: EligibilityConstraintEntity
    end
  end

  class CurrencyEntity < BaseEntity
    expose :symbol
    expose :code
  end

  class HierarchicalCategoryEntity < BaseEntity
    expose :slug
    expose :name
    expose :full_label, as: :label
  end

  class EligibilityConstraintEntity < BaseEntity
    expose :name
  end
end
