# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::AnonProxy < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class VendorAccountMessageEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :message_from
    expose :message_to
    expose :message_content
    expose :message_timestamp
    expose :relay_key
    expose :message_handler_key
  end

  class MemberContactEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :member, with: MemberEntity
    expose :formatted_address
  end

  class VendorAccountEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :member, with: MemberEntity
    expose :configuration, with: VendorConfigurationEntity
    expose :messages, with: VendorAccountMessageEntity
  end

  class DetailedVendorConfigurationEntity < VendorConfigurationEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :audit_activities, with: ActivityEntity
    expose :programs, with: ProgramEntity
    expose :instructions, with: TranslatedTextEntity
    expose :linked_success_instructions, with: TranslatedTextEntity
  end

  class DetailedVendorAccountEntity < VendorAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :latest_access_code
    expose :latest_access_code_set_at
    expose :latest_access_code_requested_at
    expose :latest_access_code_magic_link
    expose :registered_with_vendor
    expose :contact, with: MemberContactEntity
  end

  class DetailedMemberContactEntity < MemberContactEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail

    expose :phone
    expose :email
    expose :relay_key
    expose :external_relay_id
    expose :vendor_accounts, with: VendorAccountEntity
  end

  resource :anon_proxy do
    resource :vendor_accounts do
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::AnonProxy::VendorAccount,
        VendorAccountEntity,
      )
      Suma::AdminAPI::CommonEndpoints.get_one(
        self,
        Suma::AnonProxy::VendorAccount,
        DetailedVendorAccountEntity,
      )
      Suma::AdminAPI::CommonEndpoints.destroy(
        self,
        Suma::AnonProxy::VendorAccount,
        DetailedVendorAccountEntity,
      )
    end

    resource :vendor_configurations do
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::AnonProxy::VendorConfiguration,
        VendorConfigurationEntity,
      )

      Suma::AdminAPI::CommonEndpoints.get_one(
        self,
        Suma::AnonProxy::VendorConfiguration,
        DetailedVendorConfigurationEntity,
      )

      Suma::AdminAPI::CommonEndpoints.update(
        self,
        Suma::AnonProxy::VendorConfiguration,
        DetailedVendorConfigurationEntity,
      ) do
        params do
          optional :enabled, type: Boolean
          optional :app_install_link, type: String
          optional(:instructions, type: JSON) { use :translated_text }
          optional(:linked_success_instructions, type: JSON) { use :translated_text }
        end
      end

      Suma::AdminAPI::CommonEndpoints.programs_update(
        self,
        Suma::AnonProxy::VendorConfiguration,
        DetailedVendorConfigurationEntity,
      )
    end

    resource :member_contacts do
      params do
        requires(:member, type: JSON) { use :model_with_id }
        requires :type, type: Symbol, values: [:email, :phone]
      end
      post :provision do
        (member = Suma::Member[params[:member][:id]]) or forbidden!
        contact, created = Suma::AnonProxy::MemberContact.ensure_anonymous_contact(member, params[:type])
        unless created
          msg = "Member #{member.name} already has a contact for #{params[:type]}. Delete it first and try again."
          adminerror!(409, msg)
        end
        created_resource_headers(contact.id, contact.admin_link)
        status 200
        present contact, with: DetailedMemberContactEntity
      end

      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::AnonProxy::MemberContact,
        MemberContactEntity,
      )

      Suma::AdminAPI::CommonEndpoints.get_one(
        self,
        Suma::AnonProxy::MemberContact,
        DetailedMemberContactEntity,
      )

      Suma::AdminAPI::CommonEndpoints.update(
        self,
        Suma::AnonProxy::MemberContact,
        DetailedMemberContactEntity,
      ) do
        params do
          optional :email, type: String
          optional :phone, type: String
        end
      end

      Suma::AdminAPI::CommonEndpoints.destroy(
        self,
        Suma::AnonProxy::MemberContact,
        DetailedMemberContactEntity,
      )
    end
  end
end
