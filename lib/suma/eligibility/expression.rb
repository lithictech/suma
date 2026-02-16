# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Expression < Suma::Postgres::Model(:eligibility_expressions)
  many_to_one :left, class: self
  many_to_one :right, class: self
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"

  LEAF = :leaf
  BRANCH = :branch

  # Leaf nodes have attribute set;
  # branch nodes do not have attribute set.
  # Branch nodes may have left and/or right, or neither, set.
  def type = self.attribute_id ? LEAF : BRANCH
  def leaf? = self.type == LEAF
  def branch? = self.type == BRANCH

  # Return left and right subexpressions, if set.
  # @return [Array<Suma::Eligibility::Expression]
  def subexpressions = [self.left, self.right].compact

  # Return the Ruby operator for the AND/OR.
  def ruby_operator = self.operator == "OR" ? :| : :&

  # Return all attributes used in the expression, recursively.
  # @return [Sequel::IdentitySet<Suma::Eligibility::Attribute>]
  def referenced_attributes(accum: Sequel::IdentitySet.new)
    if self.leaf?
      accum << self.attribute
      return accum
    end
    self.subexpressions.each { |e| e.referenced_attributes(accum:) }
    return accum
  end

  def to_formula_str
    return "'#{self.attribute.name}'" if self.leaf?
    substrs = self.subexpressions.map(&:to_formula_str).reject(&:empty?)
    return "" if substrs.empty?
    return substrs[0] if substrs.size == 1
    return "(#{substrs[0]} #{self.operator} #{substrs[1]})"
  end

  class SerializationError < StandardError; end

  # Return a serializable object representing the expression.
  # Can be deserialized using deserialize.
  def serialize

  end

  # Deserialize an instance from a serialized version.
  # If any invalid attribute IDs are used, they are ignored,
  # and the subexpression will be empty.
  def self.deserialize

  end
end
