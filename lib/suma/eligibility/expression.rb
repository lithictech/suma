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
  # @return [Hash]
  def serialize
    return {attr: self.attribute.id, name: self.attribute.name, fqn: self.attribute.fqn_label} if self.leaf?
    h = {}
    h[:left] = self.left.serialize if self.left
    h[:right] = self.right.serialize if self.right
    h[:op] = self.operator
    return h
  end

  class << self
    # Deserialize an instance from a serialized version.
    # If any invalid attribute IDs are used, they are ignored,
    # and the subexpression will be empty.
    # @param arg [Hash]
    # @return [self]
    def deserialize(arg)
      self.db.transaction do
        r = self._deserialize(arg)
        r ||= self.create
        return r
      end
    end

    def _deserialize(arg)
      return nil if arg.nil?
      if arg[:attr]
        attribute = Suma::Eligibility::Attribute[arg[:attr]]
        return nil if attribute.nil?
        return self.create(attribute:)
      end
      h = {}
      h[:left] = self._deserialize(arg[:left]) if arg[:left]
      h[:right] = self._deserialize(arg[:right]) if arg[:right]
      h[:operator] = arg[:op] if arg[:op]
      return self.create(h)
    end
  end

  class Token < Suma::TypedStruct
    attr_reader :id, :value, :label, :type

    def initialize(**kwargs)
      kwargs[:type] = kwargs[:type].to_sym if kwargs[:type]
      super
    end

    def self.constant(s, type) = self.new(id: s, value: s, label: s, type:)
  end

  module Tokenizer
    PAREN = :paren
    OPERATOR = :operator
    VARIABLE = :variable
    TYPES = [PAREN, OPERATOR, VARIABLE].freeze

    TOK_PAREN_OPEN = Token.constant("(", PAREN)
    TOK_PAREN_CLOSE = Token.constant(")", PAREN)
    PAREN_TOKENS = [TOK_PAREN_OPEN, TOK_PAREN_CLOSE].freeze

    TOK_OP_AND = Token.constant("AND", OPERATOR)
    TOK_OP_OR = Token.constant("OR", OPERATOR)
    OPERATOR_TOKENS = [TOK_OP_AND, TOK_OP_OR].freeze

    class Detokenization < Suma::TypedStruct
      attr_reader :serialized, :warnings
    end

    class << self
      # Tokenize a serialized expression (see +Suma::Eligibility::Expression#serialize+).
      # @param expr [Hash]
      # @return [Array<Suma::Eligibility::Expression::Token>]
      def tokenize(expr, depth: 0)
        if expr[:attr]
          return [
            Suma::Eligibility::Expression::Token.new(
              id: expr.fetch(:attr),
              value: expr.fetch(:fqn),
              label: expr.fetch(:name),
              type: VARIABLE,
            ),
          ]
        end
        result = []
        result << TOK_PAREN_OPEN if depth.positive?
        result.concat(self.tokenize(expr[:left], depth: depth + 1)) if expr[:left]
        result << TOK_OP_AND if expr[:op] == "AND"
        result << TOK_OP_OR if expr[:op] == "OR"
        result.concat(self.tokenize(expr[:right], depth: depth + 1)) if expr[:right]
        result << TOK_PAREN_CLOSE if depth.positive?
        return result
      end

      # Parse a tokenized expression into one that can be passed to +Suma::Eligibility::Expression#deserialize+.
      # @param tokens [Array<Suma::Eligibility::Expression::Token>]
      # @return [Detokenization]
      def detokenize(tokens)
        ser = {}
        err = self._detokenize(tokens, ser)
        return Detokenization.new(serialized: ser, warnings: [err].compact)
      end

      def _detokenize(tokens, _serialized)
        return nil if tokens.empty?
        depth = 0
        (0..(tokens.length - 1)).each do |i|
          t = tokens[i]
          return "Invalid type '#{t.type}'" unless [PAREN, OPERATOR, VARIABLE].include?(t.type)
          return "Invalid parenthesis id '#{t.id}'" if t.type == PAREN && !"()".include?(t.id)
          return "Invalid operator id '#{t.id}'" if t.type == OPERATOR && !["AND", "OR"].include?(t.id)
          prev = i.zero? ? nil : tokens[i - 1]
          nxt = tokens[i + 1]
          depth += 1 if t.id === "("
          if t.id === ")"
            depth -= 1
            return "Unmatched closing parenthesis" if depth.negative?
          end
          if t.type === OPERATOR
            return "'#{t.value}' cannot appear here" if !prev || prev.value === "(" || prev.type === OPERATOR
            return "Expression cannot end with '#{t.value}'" unless nxt
          end
          if (t.type === VARIABLE) && prev && (prev.type === VARIABLE || prev.value === ")")
            return "Missing operator before '#{t.value}'"
          end
          if t.id === "("
            return "Empty parentheses are not allowed" if nxt && nxt.value === ")"
            return "Missing operator before '('" if prev && (prev.type === VARIABLE || prev.value === ")")
          end
          return "Operator before ')' is invalid" if (t.id === ")") && prev && prev.type === OPERATOR
        end

        return "Unmatched opening parenthesis" if depth != 0
        last = tokens[tokens.length - 1]
        return "Expression cannot end with '#{last.value}'" if last.type === OPERATOR
        return nil
      end
    end
  end
end
