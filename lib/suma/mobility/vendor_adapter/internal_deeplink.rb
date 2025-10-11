# frozen_string_literal: true

class Suma::Mobility::VendorAdapter::InternalDeeplink
  include Suma::Mobility::VendorAdapter

  VENDOR_NAME = "Acme Mobility"

  def begin_trip(_trip) = raise Unsupported
  def end_trip(_trip) = raise Unsupported
  def uses_deep_linking? = true
  def send_receipts? = false

  def find_anon_proxy_vendor_account(member)
    vendor = Suma.cached_get("internal_deeplink_vendor") do
      Suma::Vendor.find!(name: VENDOR_NAME)
    end
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end
end
