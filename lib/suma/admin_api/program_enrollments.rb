# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::ProgramEnrollments < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

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
        requires :program_id, type: Integer
        optional :member_id, type: Integer
        optional :organization_id, type: Integer
        at_least_one_of :member_id, :organization_id
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Program::Enrollment,
      ProgramEnrollmentEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Program::Enrollment,
      ProgramEnrollmentEntity,
    ) do
      params do
        optional :approved_at, type: Time
        optional :unenrolled_at, type: Time
      end
    end
  end
end
