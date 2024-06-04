# frozen_string_literal: true

require "faker"

require "suma"
require "suma/fixtures"
require "suma/member"

module Suma::Fixtures::Sessions
  extend Suma::Fixtures

  fixtured_class Suma::Member::Session

  base :session do
    self.peer_ip ||= Faker::Internet.ip_v4_address
    self.user_agent ||= Faker::Internet.user_agent
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance
  end

  decorator :for do |member=nil|
    member = Suma::Fixtures.member(**member).create unless member.is_a?(Suma::Member)
    self.member = member
  end

  decorator :impersonating do |member=nil|
    member = Suma::Fixtures.member(**member).create unless member.is_a?(Suma::Member)
    self.impersonating = member
  end
end
