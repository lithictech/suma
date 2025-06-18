# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Organizations < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedOrganizationEntity < OrganizationEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :ordinal
    expose :membership_verification_email
    expose :membership_verification_front_template_id
    expose :membership_verification_member_outreach_template, with: TranslatedTextEntity
    expose :audit_activities, with: ActivityEntity
    expose :memberships, with: OrganizationMembershipEntity
    expose :former_memberships, with: OrganizationMembershipEntity
    expose :program_enrollments, with: ProgramEnrollmentEntity
    expose :roles, with: RoleEntity
  end

  resource :organizations do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
    ) do
      params do
        requires :name, type: String, allow_blank: false
        optional :ordinal, type: Float, default: 0
        optional :membership_verification_email, type: String, allow_blank: true
        optional :membership_verification_front_template_id, type: String, allow_blank: true
        optional(:membership_verification_member_outreach_template, type: JSON) { use :translated_text }
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Organization,
      DetailedOrganizationEntity,
      around: lambda do |rt, m, &block|
        roles = rt.params.delete(:roles)
        block.call
        if roles
          role_models = Suma::Role.where(id: roles.map { |r| r[:id] }).all
          m.replace_roles(role_models)
          m.audit_activity(
            "rolechange",
            member: rt.admin_member,
            action: m.roles.map(&:name).join(", "),
          )
        end
      end,
    ) do
      params do
        optional :name, type: String, allow_blank: false
        optional :ordinal, type: Float, default: 0
        optional :membership_verification_email, type: String, allow_blank: true
        optional :membership_verification_front_template_id, type: String, allow_blank: true
        optional(:membership_verification_member_outreach_template, type: JSON) { use :translated_text }
        optional :roles, type: Array[JSON] do
          use :model_with_id
        end
      end
    end
  end
end
