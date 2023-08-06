# frozen_string_literal: true

require "suma/fixtures"
require "suma/anon_proxy/member_contact"

module Suma::Fixtures::AnonProxyMemberContacts
  extend Suma::Fixtures

  fixtured_class Suma::AnonProxy::MemberContact

  base :anon_proxy_member_contact do
    self.relay_key ||= "fake-email-relay"
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    relay = Suma::AnonProxy::Relay.create!(instance.relay_key)
    instance.send("#{relay.transport}=", relay.provision(instance.member)) if !instance.email && !instance.sms
    instance
  end

  decorator :email do |v=nil|
    self.sms = nil
    self.email = v # if nil, this gets set in before_saving
    self.relay_key = "fake-email-relay"
  end

  decorator :sms do |v=nil|
    self.sms = v
    self.email = nil
    self.relay_key = "fake-sms-relay"
  end
end
