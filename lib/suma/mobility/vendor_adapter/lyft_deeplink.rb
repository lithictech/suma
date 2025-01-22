# frozen_string_literal: true

require "suma/lyft"

class Suma::Mobility::VendorAdapter::LyftDeeplink
  include Suma::Mobility::VendorAdapter

  def requires_vendor_account? = false
  def uses_deep_linking? = true

  def find_anon_proxy_vendor_account(member)
    vendor = Suma::Vendor.where(name: Suma::Lyft::VENDOR_NAME)
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end
end
