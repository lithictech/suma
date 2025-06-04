# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/organization"

module Suma::Fixtures::Organizations
  extend Suma::Fixtures

  fixtured_class Suma::Organization

  base :organization do
    self.name ||= (Faker::Company.name + " " + SecureRandom.hex(2))
  end

  before_saving do |instance|
    instance
  end

  decorator :with_membership_of, presave: true do |member={}|
    member = Suma::Fixtures.member(**member).create unless member.is_a?(Suma::Member)
    self.add_membership(member:)
  end
end
