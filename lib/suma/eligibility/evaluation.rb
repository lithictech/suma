# frozen_string_literal: true

require "suma/eligibility"
require "suma/terminal"

class Suma::Eligibility::Evaluation
  class << self
    # @param member [Suma::Member]
    # @param resource [Suma::Postgres::Model]
    def evaluate(member, resource)
      requirements = Suma::Eligibility::Requirement.for_resource(resource).all
      expressions = requirements.map(&:expression)
      # Pull the attributes from the expression, NOT the member.
      # This avoids looking at all attributes the member has,
      # which is often a lot larger than the attributes a resource uses.
      expression_attrs = Suma::Eligibility::Attribute.accumulate(
        Sequel::IdentitySet.flatten(*requirements.map { |r| r.expression.referenced_attributes }),
      )

      assignments = Suma::Eligibility::MemberAssignment.where(member:, attribute_id: expression_attrs.map(&:id)).all
      member_attrs = Suma::Eligibility::Attribute.accumulate(assignments.map(&:attribute))
      bitmap = {}
      expressions.each do |expr|
        ok = self.evaluate_expression(expr, member_attrs)
        bitmap[expr.id] = ok
      end
      return self.new(assignments, expression_attrs, expressions, bitmap)
    end

    # Evaluate this expression for the given attribute.
    # @param expr [Suma::Eligibility::Expression]
    # @param attrs [Set<Suma::Eligibility::Attribute>]
    def evaluate_expression(expr, attrs)
      return attrs.include?(expr.attribute) if expr.leaf?
      results = expr.subexpressions.map { |e| self.evaluate_expression(e, attrs) }
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

  # @return [Sequel::IdentitySet<Suma::Eligibility::Attribute>]
  attr_reader :attributes

  # @return [Sequel::IdentitySet<Suma::Eligibility::Expression>]
  attr_reader :expressions

  # @return [Hash{Integer => Boolean}]
  attr_reader :bitmap

  def access? = @access

  def initialize(assignments, attrs, exprs, bitmap)
    @member_assignments = assignments
    @attributes = attrs
    @expressions = exprs
    @bitmap = bitmap
    @access = bitmap.values.any?
  end

  # Represent the evaluation as tables.
  def to_table
    assignment_rows = self.member_assignments.map do |ma|
      row = [ma.attribute.name]
      row << case ma.source_type
        when "member"
          "self"
        when "role"
          role = Suma::Role[ma.source_ids[0]]
          "role #{role.name}"
        when "membership"
          om = Suma::Organization::Membership[ma.source_ids[0]]
          "membership in #{om.organization_label}"
        when "organization_role"
          org = Suma::Organization[ma.source_ids[0]]
          role = Suma::Role[ma.source_ids[1]]
          "role #{role.name} for #{org.name}"
        else
          raise Suma::InvariantViolation, "unexpected source type: #{ma.inspect}"
      end
      row << ma.depth.to_s
    end
    assignment_rows.sort!
    assignments = Suma::Terminal.ascii_table(assignment_rows, headers: ["Attribute", "From", "Depth"])

    expr_rows = self.expressions.map do |expr|
      [expr.to_formula_str, self.bitmap[expr.id] ? "PASS" : "fail"]
    end
    expressions = Suma::Terminal.ascii_table(expr_rows, headers: ["Expression", "Result"])
    return {assignments:, expressions:}
  end
end
