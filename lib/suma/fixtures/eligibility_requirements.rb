# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityRequirements
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Requirement

  base :eligibility_requirement do
  end

  before_saving do |instance|
    instance
  end

  decorator :of, presave: true do |o|
    if o.is_a?(Suma::Program)
      self.add_program(o)
    elsif o.is_a?(Suma::Payment::Trigger)
      self.add_payment_trigger(o)
    else
      raise ArgumentError, "invalid requirement resource #{o}"
    end
  end

  decorator :attribute do |attr={}|
    self.expression = Suma::Fixtures.eligibility_expression.attribute(attr).create
  end
end
