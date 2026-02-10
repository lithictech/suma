# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::EligibilityAttributes < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedEligibilityAttribute < EligibilityAttributeEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :assignments, with: EligibilityAssignmentEntity
    expose :referenced_requirements, with: EligibilityRequirementEntity
  end

  resource :eligibility_attributes do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Eligibility::Attribute,
      EligibilityAttributeEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Eligibility::Attribute,
      EligibilityAttributeEntity,
    ) do
      params do
        requires :name, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Eligibility::Attribute,
      DetailedEligibilityAttribute,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Eligibility::Attribute,
      DetailedEligibilityAttribute,
    ) do
      params do
        optional :name, type: String
      end
    end
  end
end
