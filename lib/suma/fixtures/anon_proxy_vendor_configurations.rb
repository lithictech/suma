# frozen_string_literal: true

require "suma/fixtures"
require "suma/anon_proxy/vendor_configuration"

module Suma::Fixtures::AnonProxyVendorConfigurations
  extend Suma::Fixtures

  fixtured_class Suma::AnonProxy::VendorConfiguration

  base :anon_proxy_vendor_configuration do
    self.uses_email = Suma::Fixtures.nilor(self.uses_email, [true, false].sample)
    self.uses_sms = Suma::Fixtures.nilor(self.uses_sms, !self.uses_email)
    self.enabled = Suma::Fixtures.nilor(self.enabled, true)
    self.message_handler_key ||= "fake-handler"
    self.app_launch_link ||= Faker::Internet.url
  end

  before_saving do |instance|
    instance.vendor ||= Suma::Fixtures.vendor.create
    instance
  end

  decorator :disabled do
    self.enabled = false
  end

  decorator :sms do
    self.uses_email = false
    self.uses_sms = true
  end

  decorator :email do
    self.uses_email = true
    self.uses_sms = false
  end
end
