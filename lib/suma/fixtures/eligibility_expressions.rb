# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityExpressions
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Expression

  base :eligibility_expression do
  end

  before_saving do |instance|
    if instance.empty? && instance.type.nil?
      instance.operator = "AND"
      instance.type = "binary"
    end
    instance
  end

  decorator :and do
    self.operator = "AND"
    self.type = "binary"
  end

  decorator :or do
    self.operator = "OR"
    self.type = "binary"
  end

  decorator :not do
    self.operator = "NOT"
    self.type = "unary"
  end

  decorator :attribute do |attr={}|
    self.type = "attribute"
    attr = {name: attr} if attr.is_a?(String)
    attr = Suma::Fixtures.eligibility_attribute.create(attr) unless attr.is_a?(Suma::Eligibility::Attribute)
    self.attribute = attr
  end

  # Need to call this as a pair to avoid implicit hash arg stuff
  # that would require a change to FluentFixtures itself.
  decorator :binary do |op, (left_arg, right_arg)|
    self.type = "binary"
    self.operator = op
    self.left = Suma::Fixtures::EligibilityExpressions.arg_to_expr(left_arg)
    self.right = Suma::Fixtures::EligibilityExpressions.arg_to_expr(right_arg)
  end

  decorator :unary do |op, left_arg|
    self.type = "unary"
    self.operator = op
    self.left = Suma::Fixtures::EligibilityExpressions.arg_to_expr(left_arg)
  end

  class << self
    def arg_to_expr(arg)
      return arg if arg.nil?
      return Suma::Fixtures.eligibility_expression.attribute(arg).create if
        arg.is_a?(Suma::Eligibility::Attribute)
      return arg if arg.is_a?(Suma::Eligibility::Expression)
      arg = {name: arg} if arg.is_a?(String)
      return Suma::Fixtures.eligibility_expression.create(arg)
    end
  end
end
