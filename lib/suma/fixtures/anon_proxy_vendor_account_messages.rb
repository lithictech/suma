# frozen_string_literal: true

require "suma/fixtures"
require "suma/anon_proxy/vendor_account"

module Suma::Fixtures::AnonProxyVendorAccountMessages
  extend Suma::Fixtures

  fixtured_class Suma::AnonProxy::VendorAccountMessage

  base :anon_proxy_vendor_account_message do
    self.message_id ||= SecureRandom.hex(4)
    self.message_from ||= Faker::Internet.email
    self.message_to ||= Faker::Internet.email
    self.message_content ||= Faker::Lorem.paragraph
    self.message_timestamp ||= Time.now
    self.relay_key ||= "fake-relay"
    self.message_handler_key ||= "fake-handler"
  end

  before_saving do |instance|
    instance.vendor_account ||= Suma::Fixtures.anon_proxy_vendor_account.with_contact.create
    instance.outbound_delivery ||= Suma::Fixtures.message_delivery.with_recipient(instance.vendor_account.member).create
    instance
  end
end
