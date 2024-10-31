# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::ProgramEnrollments < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities
  class DetailedProgramEnrollmentEntity < ProgramEnrollmentEntity
    include Suma::AdminAPI::Entities
    expose :approved?, as: :approved
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
    ) do
      params do
        requires(:program, type: JSON) { use :model_with_id }
        optional(:member, type: JSON) { use :model_with_id }
        optional(:organization, type: JSON) { use :model_with_id }
        exactly_one_of :member, :organization
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
    ) do
      params do
        optional :approved, type: Boolean
        optional(:approved_by, type: JSON) { use :model_with_id }
        optional :unenrolled, type: Boolean
        optional(:unenrolled_by, type: JSON) { use :model_with_id }
      end
    end
  end
end
