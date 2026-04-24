# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::OrganizationRegistrationLinks < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedOrganizationRegistrationLinkEntity < OrganizationRegistrationLinkEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :currently_within_schedule do |instance, _options|
      instance.within_schedule?(Time.now)
    end
    expose :durable_url
    expose :durable_url_qr_code_data_url, as: :durable_url_qr_code
    expose :intro, with: TranslatedTextEntity
    expose :memberships, with: OrganizationMembershipEntity
  end

  resource :organization_registration_links do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization::RegistrationLink,
      OrganizationRegistrationLinkEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Organization::RegistrationLink,
      DetailedOrganizationRegistrationLinkEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Organization::RegistrationLink,
      DetailedOrganizationRegistrationLinkEntity,
      around: lambda do |_rt, m, &block|
        block.call
        m.organization.audit_activity("reglink", action: "#{m.admin_label}, ical_event=#{m.ical_event}")
      end,
    ) do
      params do
        requires(:organization, type: JSON) { use :model_with_id }
        requires(:intro, type: JSON) { use :translated_text }
        optional :ical_event, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Organization::RegistrationLink,
      DetailedOrganizationRegistrationLinkEntity,
      around: lambda do |rt, m, &block|
        block.call
        m.organization.audit_activity("changeregcode", action: "ical_event=#{m.ical_event}") if
          rt.params.key?(:ical_event)
      end,
    ) do
      params do
        optional(:intro, type: JSON) { use :translated_text }
        optional :ical_event, type: String
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Organization::RegistrationLink,
      DetailedOrganizationRegistrationLinkEntity,
      around: lambda do |_rt, m, &block|
        block.call
        m.organization.audit_activity("deleteregcode", action: m)
      end,
    )
  end
end
