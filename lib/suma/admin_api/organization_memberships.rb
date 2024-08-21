# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::OrganizationMemberships < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :organization_memberships do
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization::Membership,
      OrganizationMembershipEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
    )

    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization::Membership,
      OrganizationMembershipEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Organization::Membership,
      OrganizationMembershipEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
    ) do
      params do
        requires(:member, type: JSON) { use :model_with_id }
        optional(:verified_organization, type: JSON) { use :model_with_id }
        optional :unverified_organization_name, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Organization::Membership,
      OrganizationMembershipEntity,
      access: Suma::Member::RoleAccess::ADMIN_MEMBERS,
    ) do
      params do
        optional(:verified_organization, type: JSON) { use :model_with_id }
        optional :unverified_organization_name, type: String
      end
    end
  end
end
