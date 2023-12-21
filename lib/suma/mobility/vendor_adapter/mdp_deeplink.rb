# frozen_string_literal: true

require "suma/lime"

class Suma::Mobility::VendorAdapter::MdpDeeplink
  include Suma::Mobility::VendorAdapter

  def requires_vendor_account? = true
  def uses_deep_linking? = false

  def find_anon_proxy_vendor_account(member)
    vendor = Suma::Vendor.where(name: Suma::Lime::VENDOR_NAME)
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end
end
