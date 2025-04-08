# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Roles < Suma::AdminAPI::V1
  class RoleEntity < Suma::AdminAPI::Entities::RoleEntity
    include Suma::AdminAPI::Entities::AutoExposeBase
  end

  class DetailedRoleEntity < RoleEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :members, with: Suma::AdminAPI::Entities::MemberEntity
    expose :organizations, with: Suma::AdminAPI::Entities::OrganizationEntity
    expose :program_enrollments, with: Suma::AdminAPI::Entities::ProgramEnrollmentEntity
  end

  resource :roles do
    desc "Return all roles, ordered by name"
    get do
      check_role_access!(admin_member, :read, :admin_access) # This will always pass but better to be explicit
      ds = Suma::Role.dataset.order(:name)
      use_http_expires_caching 2.hours
      present_collection ds, with: RoleEntity
    end

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Role,
      DetailedRoleEntity,
    ) do
      params do
        requires :name, type: String, allow_blank: false
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Role,
      DetailedRoleEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Role,
      DetailedRoleEntity,
    ) do
      params do
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
