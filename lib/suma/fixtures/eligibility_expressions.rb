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

  # Need to call this as a pair to avoid implicit hash arg stuff
  # that would require a change to FluentFixtures itself.
  decorator :branch do |(left_arg, right_arg)|
    left = if left_arg.is_a?(Suma::Eligibility::Attribute)
             Suma::Fixtures.eligibility_expression.leaf(left_arg).create
            elsif left_arg.is_a?(Suma::Eligibility::Expression)
              left_arg
            elsif left_arg
              Suma::Fixtures.eligibility_expression.create(left_arg)
            end
    right = if right_arg.is_a?(Suma::Eligibility::Attribute)
              Suma::Fixtures.eligibility_expression.leaf(right_arg).create
            elsif right_arg.is_a?(Suma::Eligibility::Expression)
              right_arg
            elsif right_arg
              Suma::Fixtures.eligibility_expression.create(right_arg)
            end
    self.left = left
    self.right = right
  end
end
