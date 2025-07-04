# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::OrganizationMemberships < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedOrganizationMembershipEntity < OrganizationMembershipEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :matched_organization, with: OrganizationEntity
    expose :verification, with: OrganizationMembershipVerificationEntity
    expose :audit_activities, with: ActivityEntity
  end

  resource :organization_memberships do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization::Membership,
      OrganizationMembershipEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization::Membership,
      DetailedOrganizationMembershipEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Organization::Membership,
      DetailedOrganizationMembershipEntity,
      around: lambda do |_rt, m, &block|
        block.call
        m.audit_activity("create")
        if (org = m.verified_organization || m.former_organization)
          org.audit_activity(
            "addmember",
            action: m.member,
          )
          m.member.audit_activity(
            "createmembership",
            action: org,
          )
        else
          m.member.audit_activity(
            "createmembership",
            action: "Unverified Org: #{m.unverified_organization_name}",
          )
        end
      end,
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
      DetailedOrganizationMembershipEntity,
      around: lambda do |rt, m, &block|
        remove_from_org = rt.params.delete(:remove_from_organization)
        # Removal modifies the membership so must come before block.call so it's saved
        m.remove_from_organization if remove_from_org
        block.call
        # Audits do not modify the row itself so should come after
        if remove_from_org
          m.audit_activity("end")
          m.former_organization.audit_activity(
            "removemember",
            action: "Suma::Member[#{m.member.id}] #{m.member.name}",
          )
          m.member.audit_activity(
            "endmembership",
            action: "Suma::Organization[#{m.former_organization.id}] #{m.former_organization.name}",
          )
        elsif rt.params[:verified_organization]
          m.audit_activity("verify")
          m.verified_organization.audit_activity(
            "addmember",
            action: "Suma::Member[#{m.member.id}] #{m.member.name}",
          )
          m.member.audit_activity(
            "beginmembership",
            action: "Suma::Organization[#{m.verified_organization.id}] #{m.verified_organization.name}",
          )
        end
      end,
    ) do
      params do
        optional(:verified_organization, type: JSON) { use :model_with_id }
        optional :unverified_organization_name, type: String
        optional :remove_from_organization, type: Boolean
      end
    end
  end
end
