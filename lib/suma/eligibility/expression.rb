# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Expression < Suma::Postgres::Model(:eligibility_expressions)
  many_to_one :left, class: self
  many_to_one :right, class: self
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
  one_to_one :requirement, class: "Suma::Eligibility::Requirement"

  # Mixin for easy usage.
  module Constants
    ATTRIBUTE = "attribute"
    UNARY = "unary"
    BINARY = "binary"

    AND = "AND"
    OR = "OR"
    NOT = "NOT"

    BINARY_OPS = [AND, OR].freeze
    UNARY_OPS = [NOT].freeze
  end

  include Constants

  class << self
    include Constants
    # Create an empty expression. We need this when creating a default in some places.
    def create_empty = self.create(type: BINARY, operator: AND)
  end

  def binary? = self.type == BINARY
  def unary? = self.type == UNARY
  def attribute? = self.type == ATTRIBUTE
  def empty? = self.attribute.nil? && self.left.nil? && self.right.nil?

  # Return left and right subexpressions, if set.
  # @return [Array<Suma::Eligibility::Expression]
  def subexpressions = [self.left, self.right].compact

  # Return all attributes used in the expression, recursively.
  # @return [Sequel::IdentitySet<Suma::Eligibility::Attribute>]
  def referenced_attributes(accum: Sequel::IdentitySet.new)
    if self.attribute?
      accum << self.attribute
      return accum
    end
    self.subexpressions.each { |e| e.referenced_attributes(accum:) }
    return accum
  end

  def to_formula_str
    return "'#{self.attribute.name}'" if self.attribute?
    substrs = self.subexpressions.map(&:to_formula_str).reject(&:empty?)
    return "" if substrs.empty?
    return "(#{self.operator} #{substrs[0]})" if self.unary?
    return substrs[0] if substrs.size == 1
    return "(#{substrs[0]} #{self.operator} #{substrs[1]})"
  end

  # Return a serializable object representing the expression.
  # Can be deserialized using deserialize.
  # @return [Hash]
  def serialize = Serializer.serialize(self)

  def tokenize
    return [] if self.empty?
    return Tokenizer.tokenize(self.serialize)
  end
end

require "suma/eligibility/expression/serializer"
require "suma/eligibility/expression/tokenizer"
