# frozen_string_literal: true

require "suma/eligibility"

class Suma::Eligibility::Evaluation
  class << self
    # @param member [Suma::Member]
    # @param resource [Suma::Postgres::Model]
    def evaluate(member, resource)
      assignments = Suma::Eligibility::MemberAssignment.where(member:).all
      attrs = self.accumulate_attributes(assignments.map(&:attribute))
      resource_reqs = Suma::Eligibility::Requirement.for_resource(resource).all
      exprs = resource_reqs.map(&:expression)
      bitmap = {}
      exprs.each do |expr|
        ok = self.evaluate_expression(expr, attrs)
        bitmap[expr.id] = ok
      end
      return self.new(assignments, attrs, exprs, bitmap)
    end

    # Evaluate this expression for the given attribute.
    # @param expr [Suma::Eligibility::Expression]
    # @param attrs [Hash{Integer => Suma::Eligibility::Attribute}]
    def evaluate_expression(expr, attrs)
      return attrs.key?(expr.attribute.id) if expr.leaf?
      results = [expr.left, expr.right].compact.map { |e| self.evaluate_expression(e, attrs) }
      ok = results.reduce(&expr.ruby_operator)
      return ok
    end

    # @param attrs [Array<Suma::Eligibility::Attribute>]
    # @param accum [Hash{Integer => Suma::Eligibility::Attribute}]
    # @return [Hash{Integer => Suma::Eligibility::Attribute}]
    def accumulate_attributes(attrs, accum: {})
      attrs.each do |attr|
        accum[attr.id] = attr
        self.accumulate_attributes([attr.parent], accum:) if attr.parent
      end
      return accum
    end
  end

  # @return [Array<Suma::Eligibility::MemberAssignment>]]
  attr_reader :member_assignments

  # @return [Hash{Integer => Suma::Eligibility::Attribute}]
  attr_reader :attributes

  # @return [Hash{Integer => Suma::Eligibility::Expression}]
  attr_reader :expressions

  # @return [Hash{Integer => Boolean}]
  attr_reader :bitmap

  def access? = @access

  def initialize(assignments, attrs, exprs, bitmap)
    @assignments = assignments
    @attributes = attrs
    @expressions = exprs
    @bitmap = bitmap
    @access = bitmap.values.any?
  end
end
