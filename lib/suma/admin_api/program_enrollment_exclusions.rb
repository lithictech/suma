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
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Program::EnrollmentExclusion,
      DetailedProgramEnrollmentExclusionEntity,
      around: lambda do |_rt, m, &block|
        block.call
        m.program.audit_activity("addexclusion", action: m)
      end,
    ) do
      params do
        requires(:program, type: JSON) { use :model_with_id }
        requires(:member, type: JSON) { use :model_with_id }
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
        m.program.audit_activity("removeexclusion", action: m)
        rt.created_resource_headers(m.program_id, m.program.admin_link)
      end,
    )
  end
end
