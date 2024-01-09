# frozen_string_literal: true

require "suma/lime"

module Suma::Mobility::VendorAdapter::DeeplinkMixin
  def requires_vendor_account? = true
  def uses_deep_linking? = true

  def _vendor_name = raise NotImplementedError

  def find_anon_proxy_vendor_account(member)
    vendor = Suma::Vendor.where(name: self._vendor_name)
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end
end
