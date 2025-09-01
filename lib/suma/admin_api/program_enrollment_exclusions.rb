# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::ProgramEnrollmentExclusions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedProgramEnrollmentExclusionEntity < ProgramEnrollmentExclusionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :created_by, with: MemberEntity
  end

  resource :program_enrollment_exclusions do
    helpers do
      def modelrepr(m)
        prefix = Suma::HasActivityAudit.model_repr(m)
        "#{prefix}(enrollee: #{Suma::HasActivityAudit.model_repr(m.enrollee)})"
      end
    end

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Program::EnrollmentExclusion,
      DetailedProgramEnrollmentExclusionEntity,
      around: lambda do |rt, m, &block|
        block.call
        m.program.audit_activity("addexclusion", action: rt.modelrepr(m))
      end,
    ) do
      params do
        requires(:program, type: JSON) { use :model_with_id }
        optional(:member, type: JSON) { use :model_with_id }
        optional(:role, type: JSON) { use :model_with_id }
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Program::EnrollmentExclusion,
      DetailedProgramEnrollmentExclusionEntity,
    )

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Program::EnrollmentExclusion,
      DetailedProgramEnrollmentExclusionEntity,
      around: lambda do |rt, m, &block|
        block.call
        m.program.audit_activity("removeexclusion", action: rt.modelrepr(m))
        rt.created_resource_headers(m.program_id, m.program.admin_link)
      end,
    )
  end
end
