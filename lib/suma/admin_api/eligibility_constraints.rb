# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::EligibilityConstraints < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedEligibilityConstraintEntity < EligibilityConstraintEntity
    include Suma::AdminAPI::Entities
    expose :offerings, with: OfferingEntity
    expose :services, with: VendorServiceEntity
    expose :configurations, with: VendorConfigurationEntity
  end

  resource :eligibility_constraints do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Eligibility::Constraint,
      EligibilityConstraintEntity,
      search_params: [:name],
    )
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Eligibility::Constraint,
      DetailedEligibilityConstraintEntity,
    ) do
      params do
        requires :name, type: String, allow_blank: false
      end
    end
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Eligibility::Constraint,
      DetailedEligibilityConstraintEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Eligibility::Constraint,
      DetailedEligibilityConstraintEntity,
    ) do
      params do
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
