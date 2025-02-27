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

  class AnonProxyMemberContactEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :member, with: MemberEntity
    expose :phone
    expose :email
    expose :relay_key
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
    expose :auth_to_vendor_key
    expose :programs, with: ProgramEntity
    expose :instructions, with: TranslatedTextEntity
  end

  class DetailedVendorAccountEntity < VendorAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :latest_access_code
    expose :latest_access_code_set_at
    expose :latest_access_code_requested_at
    expose :latest_access_code_magic_link
    expose :contact, with: AnonProxyMemberContactEntity
  end

  resource :anon_proxy do
    resource :vendor_accounts do
      Suma::AdminAPI::CommonEndpoints.get_one(
        self,
        Suma::AnonProxy::VendorAccount,
        DetailedVendorAccountEntity,
      )
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::AnonProxy::VendorAccount, VendorAccountEntity,
        search_params: [:latest_access_code_magic_link, :latest_access_code],
      )
    end

    resource :vendor_configurations do
      Suma::AdminAPI::CommonEndpoints.get_one(
        self,
        Suma::AnonProxy::VendorConfiguration,
        DetailedVendorConfigurationEntity,
      )
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::AnonProxy::VendorConfiguration,
        VendorConfigurationEntity,
      )

      Suma::AdminAPI::CommonEndpoints.programs_update(
        self,
        Suma::AnonProxy::VendorConfiguration,
        DetailedVendorConfigurationEntity,
      )
    end
  end
end
