# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::AnonProxy < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class VendorAccountMessageEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :message_from
    expose :message_to
    expose :message_content
    expose :message_timestamp
    expose :relay_key
    expose :message_handler_key
  end

  class MemberContactEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :member, with: MemberEntity
    expose :phone
    expose :email
    expose :relay_key
  end

  class VendorConfigurationEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :id
    expose :vendor, with: VendorEntity
    expose :app_install_link
    expose :uses_email
    expose :uses_sms
    expose :enabled
    expose :message_handler_key
    expose :auth_http_method
    expose :auth_url
    expose :auth_headers_label, as: :auth_headers
    expose :auth_body_template
  end

  class AnonProxyVendorAccountEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :member, with: MemberEntity
    expose :configuration, with: VendorConfigurationEntity
    expose :messages, with: VendorAccountMessageEntity
  end

  class DetailedAnonProxyVendorAccountEntity < AnonProxyVendorAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :latest_access_code
    expose :latest_access_code_set_at
    expose :latest_access_code_requested_at
    expose :latest_access_code_magic_link
    expose :contact, with: MemberContactEntity
  end

  resource :anon_proxy do
    resource :vendor_accounts do
      Suma::AdminAPI::CommonEndpoints.list(
        self,
        Suma::AnonProxy::VendorAccount, AnonProxyVendorAccountEntity,
        search_params: [:latest_access_code_magic_link, :latest_access_code],
      )
      Suma::AdminAPI::CommonEndpoints.get_one self, Suma::AnonProxy::VendorAccount, DetailedAnonProxyVendorAccountEntity
      Suma::AdminAPI::CommonEndpoints.update self, Suma::AnonProxy::VendorAccount,
                                             DetailedAnonProxyVendorAccountEntity do
        params do
          optional :latest_access_code_magic_link, type: String
          optional :latest_access_code, type: String
          optional :latest_access_code_set_at, type: Time
          optional :latest_access_code_requested_at, type: Time
        end
      end
    end
  end
end
