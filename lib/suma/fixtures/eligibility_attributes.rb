# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityAttributes
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Attribute

  base :eligibility_attribute do
    self.name ||= "#{Faker::Lorem.word}-#{SecureRandom.hex(2)}"
  end

  before_saving do |instance|
    instance
  end

  decorator :parent do |attr={}|
    attr = Suma::Fixtures.eligibility_attribute.create(attr) unless attr.is_a?(Suma::Eligibility::Attribute)
    self.parent = attr
  end

  decorator :between, presave: true do |member, resource|
    Suma::Fixtures.eligibility_assignment.of(self).to(member).create
    Suma::Fixtures.eligibility_requirement.attribute(self).create(resource:)
  end
end
