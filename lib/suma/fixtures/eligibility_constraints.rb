# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligbilityConstraints
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Constraint

  base :eligibility_constraint do
    self.name ||= Faker::Lorem.words(number: 2).join(" ") + SecureRandom.hex(2)
  end
end
