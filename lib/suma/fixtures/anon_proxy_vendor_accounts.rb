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

  decorator :with_configuration do |c={}|
    c = Suma::Fixtures.anon_proxy_vendor_configuration(c).create unless
      c.is_a?(Suma::AnonProxy::VendorConfiguration)
    self.configuration = c
  end

  decorator :with_contact do |c={}|
    self.member ||= Suma::Fixtures.member.create
    c = Suma::Fixtures.anon_proxy_member_contact(member: self.member).create(c) unless
      c.is_a?(Suma::AnonProxy::MemberContact)
    self.contact = c
  end

  decorator :with_access_code do |code, at=Time.now|
    self.replace_access_code(code, at:)
  end
end
