# frozen_string_literal: true

require "suma/lime"

class Suma::Mobility::VendorAdapter::NativeAppDeeplink
  include Suma::Mobility::VendorAdapter

  def requires_vendor_account? = true
  def uses_deep_linking? = true

  def _vendor_name = raise NotImplementedError

  def find_anon_proxy_vendor_account(member, vendor)
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end
end
