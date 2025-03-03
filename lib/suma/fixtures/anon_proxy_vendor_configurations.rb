# frozen_string_literal: true

require "suma/fixtures"
require "suma/anon_proxy/vendor_configuration"

module Suma::Fixtures::AnonProxyVendorConfigurations
  extend Suma::Fixtures

  fixtured_class Suma::AnonProxy::VendorConfiguration

  base :anon_proxy_vendor_configuration do
    self.enabled = Suma::Fixtures.nilor(self.enabled, true)
    self.auth_to_vendor_key ||= "fake"
    self.message_handler_key ||= "fake-handler"
    self.app_install_link ||= Faker::Internet.url
  end

  before_saving do |instance|
    instance.vendor ||= Suma::Fixtures.vendor.create
    instance.instructions ||= Suma::Fixtures.translated_text.create
    instance.linked_success_instructions ||= Suma::Fixtures.translated_text.create
    instance
  end

  decorator :disabled do
    self.enabled = false
  end

  decorator :with_programs, presave: true do |*programs|
    programs.each { |c| self.add_program(c) }
  end
end
