# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityExpressions
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Expression

  base :eligibility_expressions do
  end

  before_saving do |instance|
    instance.resource ||= Suma::Fixtures.program.create
    instance
  end
end
