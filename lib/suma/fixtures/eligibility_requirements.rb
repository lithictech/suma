# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityRequirements
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Requirement

  base :eligibility_requirements do
  end

  before_saving do |instance|
    instance
  end

  decorator :attribute do |name=Faker::Lorem.word|
    self.attribute = Suma::Fixtures.eligibility_attribute(name:).create
  end
end
