# frozen_string_literal: true

require "suma/fixtures"
require "suma/anon_proxy/member_contact"

module Suma::Fixtures::AnonProxyMemberContacts
  extend Suma::Fixtures

  fixtured_class Suma::AnonProxy::MemberContact

  base :anon_proxy_member_contact do
    self.provider_key ||= "fake"
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance.email = "e#{SecureRandom.hex(2)}@example.com" if !instance.phone && !instance.email
    instance
  end

  decorator :email do
    self.phone = nil
    self.email = "e#{SecureRandom.hex(2)}@example.com"
  end
end
