# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::EligibilityAssignments < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedEligibilityAssignment < EligibilityAssignmentEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: AuditMemberEntity
  end

  resource :eligibility_assignments do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Eligibility::Assignment,
      EligibilityAssignmentEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Eligibility::Assignment,
      EligibilityAssignmentEntity,
      around: lambda do |_rt, m, &b|
        b.call
        m.attribute.audit_activity("assignattribute", action: m.assignee)
        m.assignee.audit_activity("assignattribute", action: m.attribute)
      end,
    ) do
      params do
        requires(:attribute, type: JSON) { use :model_with_id }
        optional(:member, type: JSON) { use :model_with_id }
        optional(:organization, type: JSON) { use :model_with_id }
        optional(:role, type: JSON) { use :model_with_id }
        exactly_one_of :member, :organization, :role
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Eligibility::Assignment,
      DetailedEligibilityAssignment,
    )

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Eligibility::Assignment,
      DetailedEligibilityAssignment,
      around: lambda do |_rt, m, &b|
        m.attribute.audit_activity("removeattribute", action: m.assignee)
        m.assignee.audit_activity("removeattribute", action: m.attribute)
        b.call
      end,
    )
  end
end
