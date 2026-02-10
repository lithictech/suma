# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::EligibilityRequirements < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedEligibilityRequirement < EligibilityRequirementEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: AuditMemberEntity
  end

  resource :eligibility_requirements do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Eligibility::Requirement,
      EligibilityRequirementEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Eligibility::Requirement,
      EligibilityRequirementEntity,
      around: lambda do |_rt, m, &b|
        b.call
        m.resource.audit_activity("addeligibility", action: m)
      end,
    ) do
      params do
        optional(:program, type: JSON) { use :model_with_id }
        optional(:payment_trigger, type: JSON) { use :model_with_id }
        exactly_one_of :program, :payment_trigger
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Eligibility::Requirement,
      DetailedEligibilityRequirement,
    )

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Eligibility::Requirement,
      DetailedEligibilityRequirement,
      around: lambda do |_rt, m, &b|
        m.resource.audit_activity("removedeligibility", action: m)
        b.call
      end,
    )
  end
end
