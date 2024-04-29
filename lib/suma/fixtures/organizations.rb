# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/organization"

module Suma::Fixtures::Organizations
  extend Suma::Fixtures

  fixtured_class Suma::Organization

  base :organization do
    self.name ||= Faker::Company.name
  end

  before_saving do |instance|
    instance
  end

  decorator :with_verified_membership, presave: true do |member={}|
    member = Suma::Fixtures.member(**member).create unless member.is_a?(Suma::Member)
    self.add_membership(verified_member: member)
  end

  decorator :with_unverified_membership, presave: true do |member={}|
    member = Suma::Fixtures.member(**member).create unless member.is_a?(Suma::Member)
    self.add_membership(unverified_member: member)
  end
end
