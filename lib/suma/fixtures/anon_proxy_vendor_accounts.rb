# frozen_string_literal: true

require "suma/fixtures"
require "suma/anon_proxy/vendor_account"

module Suma::Fixtures::AnonProxyVendorAccounts
  extend Suma::Fixtures

  fixtured_class Suma::AnonProxy::VendorAccount

  base :anon_proxy_vendor_account do
  end

  before_saving do |instance|
    instance.configuration ||= Suma::Fixtures.anon_proxy_vendor_configuration.create
    instance.member ||= Suma::Fixtures.member.create
    instance
  end
end
