# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityExpressions
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Expression

  base :eligibility_expression do
  end

  before_saving do |instance|
    instance
  end

  decorator :and do
    self.operator = "AND"
  end

  decorator :or do
    self.operator = "OR"
  end

  decorator :leaf do |attr={}|
    attr = Suma::Fixtures.eligibility_attribute.create(attr) unless attr.is_a?(Suma::Eligibility::Attribute)
    self.attribute = attr
  end

  # Need to do it this way to avoid implicit hash arg stuff that would require a change to FluentFixtures itself.
  decorator :branch do |(left, right)|
    left = Suma::Fixtures.eligibility_expression.create(left) if left && !left.is_a?(Suma::Eligibility::Expression)
    right = Suma::Fixtures.eligibility_expression.create(right) if right && !right.is_a?(Suma::Eligibility::Expression)
    self.left = left
    self.right = right
  end
end
