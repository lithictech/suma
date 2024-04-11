# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::OrganizationMemberships < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :organization_memberships do
    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Organization::Membership, DetailedMembershipEntity)

    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization::Membership,
      DetailedMembershipEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Organization::Membership,
      DetailedMembershipEntity,
    ) do
      params do
        requires(:member, type: JSON) { use :model_with_id }
        requires(:organization, type: JSON) { use :model_with_id }
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Organization::Membership,
      DetailedMembershipEntity,
    ) do
      params do
        requires(:member, type: JSON) { use :model_with_id }
        requires(:organization, type: JSON) { use :model_with_id }
      end
    end
  end
end
