# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::ProgramEnrollments < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedProgramEnrollmentEntity < ProgramEnrollmentEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :enrolled?, as: :enrolled
    expose :ever_approved?, as: :approved
    expose :approved_by, with: MemberEntity
    expose :unenrolled?, as: :unenrolled
    expose :unenrolled_by, with: MemberEntity
  end

  resource :program_enrollments do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Program::Enrollment,
      ProgramEnrollmentEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Program::Enrollment,
      ProgramEnrollmentEntity,
      around: lambda do |rt, m, &b|
        m.approved = true
        m.approved_by = rt.admin_member
        b.call
      end,
    ) do
      params do
        requires(:program, type: JSON) { use :model_with_id }
        optional(:member, type: JSON) { use :model_with_id }
        optional(:organization, type: JSON) { use :model_with_id }
        optional(:role, type: JSON) { use :model_with_id }
        exactly_one_of :member, :organization, :role
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Program::Enrollment,
      DetailedProgramEnrollmentEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Program::Enrollment,
      DetailedProgramEnrollmentEntity,
      around: lambda do |rt, m, &block|
        m.approved_by = rt.admin_member if rt.params[:approved]
        m.unenrolled_by = rt.admin_member if rt.params[:unenrolled]
        block.call
      end,
    ) do
      params do
        optional :approved, type: Boolean
        optional :unenrolled, type: Boolean
      end
    end
  end
end
