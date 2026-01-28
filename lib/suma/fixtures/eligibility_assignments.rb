# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityAssignments
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Assignment

  base :eligibility_assignments do
    self.name ||= Faker::Lorem.word
  end

  before_saving do |instance|
    instance
  end
end
