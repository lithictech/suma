# frozen_string_literal: true

require "suma/lyft"

class Suma::Mobility::VendorAdapter::LyftDeeplink
  include Suma::Mobility::VendorAdapter

  def requires_vendor_account? = false
  def uses_deep_linking? = true

  protected def deeplink_vendor = Suma::Lyft.deeplink_vendor

  def find_anon_proxy_vendor_account(member)
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor: self.deeplink_vendor)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end
end
