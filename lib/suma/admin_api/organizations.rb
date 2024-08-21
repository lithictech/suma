# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Organizations < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedOrganizationEntity < OrganizationEntity
    include Suma::AdminAPI::Entities
    expose :memberships, with: OrganizationMembershipEntity
  end

  resource :organizations do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
      search_params: [:name],
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
      access: Suma::Member::RoleAccess::ADMIN_MANAGEMENT,
    ) do
      params do
        requires :name, type: String, allow_blank: false
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
      access: Suma::Member::RoleAccess::ADMIN_MANAGEMENT,
    ) do
      params do
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
