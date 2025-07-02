# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::AnonProxyVendorAccounts < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class VendorAccountRegistrationEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :external_program_id
    expose :external_registration_id
  end

  class DetailedVendorAccountEntity < AnonProxyVendorAccountEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :latest_access_code
    expose :latest_access_code_set_at
    expose :latest_access_code_requested_at
    expose :latest_access_code_magic_link
    expose :contact, with: AnonProxyMemberContactEntity
    expose :registrations, with: VendorAccountRegistrationEntity
  end

  resource :anon_proxy_vendor_accounts do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::AnonProxy::VendorAccount,
      AnonProxyVendorAccountEntity,
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
end
