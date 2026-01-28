# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityAttributes
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Attribute

  base :eligibility_attribute do
    self.name ||= Faker::Lorem.word
  end

  before_saving do |instance|
    instance
  end
end
