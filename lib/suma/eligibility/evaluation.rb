# frozen_string_literal: true

require "suma/eligibility"
require "suma/terminal"

class Suma::Eligibility::Evaluation
  class << self
    # @param member [Suma::Member]
    # @param resource [Suma::Eligibility::Resource::InstanceMethods]
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
      return attrs.include?(expr.attribute) if expr.attribute?
      results = expr.subexpressions.map { |e| self.evaluate_expression(e, attrs) }
      return false if results.empty?
      case expr.operator
        when Suma::Eligibility::Expression::AND
          return results.reduce(&:&)
        when Suma::Eligibility::Expression::OR
          return results.reduce(&:|)
        when Suma::Eligibility::Expression::NOT
          raise Suma::InvariantViolation, "unary expects 1 subexpression" unless results.length == 1
          return !results[0]
        else
          raise Suma::InvariantViolation, "invalid operator"
      end
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
    @access = bitmap.values.any? || (Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE && exprs.empty?)
  end

  # Represent the evaluation as ASCII tables.
  # Result is a hash with :assignments and :expressions keys,
  # each value is a table string for console rendering.
  def to_ascii_tables
    stbl = self.to_structured_tables
    assignment_rows = stbl[:assignments].map do |ma|
      row = [ma.label]
      row << case ma.source_type
        when Suma::Eligibility::MemberAssignment::MEMBER
          "self"
        when Suma::Eligibility::MemberAssignment::ROLE
          role = Suma::Role.find!(ma.sources[0][:id])
          "role #{role.name}"
        when Suma::Eligibility::MemberAssignment::MEMBERSHIP
          om = Suma::Organization::Membership.find!(ma.sources[0][:id])
          "membership in #{om.organization_label}"
        when Suma::Eligibility::MemberAssignment::ORGANIZATION_ROLE
          om = Suma::Organization::Membership.find!(ma.sources[0][:id])
          role = Suma::Role.find!(ma.sources[1][:id])
          "role #{role.name} for #{om.verified_organization.name}"
        else
          raise Suma::InvariantViolation, "unexpected source type: #{ma.inspect}"
      end
      row << ma.depth.to_s
    end
    assignment_rows.sort!
    assignments = Suma::Terminal.ascii_table(assignment_rows, headers: ["Attribute", "From", "Depth"])

    expr_rows = stbl[:expressions].map do |expr|
      [expr.formula, expr.passed ? "PASS" : "fail"]
    end
    expressions = Suma::Terminal.ascii_table(expr_rows, headers: ["Expression", "Result"])
    return {assignments:, expressions:}
  end

  Assignment = Struct.new(
    :attribute_id,
    :attribute_admin_link,
    :label,
    :depth,
    :source_type,
    :sources,
  )
  Expression = Struct.new(
    :requirement_id,
    :requirement_label,
    :requirement_admin_link,
    :expression_id,
    :formula,
    :passed,
  )

  # Represent the evaluation as a series of structs,
  # for easier use in rendering.
  def to_structured_tables
    assignments = self.member_assignments.map do |ma|
      a = Assignment.new
      a.attribute_id = ma.attribute.id
      a.attribute_admin_link = ma.attribute.admin_link
      a.label = ma.attribute.fqn_label
      a.depth = ma.depth
      a.source_type = ma.source_type
      a.sources = ma.sources.map { |o| {id: o.id, label: o.admin_label, admin_link: o.admin_link} }
      a
    end
    assignments.sort_by! { |a| [a.label, a.depth] }

    expressions = self.expressions.map do |expr|
      e = Expression.new
      e.expression_id = expr.id
      e.requirement_id = expr.requirement.id
      e.requirement_label = expr.requirement.admin_label
      e.requirement_admin_link = expr.requirement.admin_link
      e.formula = expr.to_formula_str
      e.passed = self.bitmap[expr.id]
      e
    end
    return {assignments:, expressions:}
  end
end
