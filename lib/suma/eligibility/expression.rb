# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Expression < Suma::Postgres::Model(:eligibility_expressions)
  many_to_one :left, class: self
  many_to_one :right, class: self
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
  one_to_one :requirement, class: "Suma::Eligibility::Requirement"

  LEAF = :leaf
  BRANCH = :branch

  # Leaf nodes have attribute set;
  # branch nodes do not have attribute set.
  # Branch nodes may have left and/or right, or neither, set.
  def type = self.attribute_id ? LEAF : BRANCH
  def leaf? = self.type == LEAF
  def branch? = self.type == BRANCH
  def empty? = self.attribute.nil? && self.left.nil? && self.right.nil?

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

  def tokenize
    return [] if self.empty?
    return Tokenizer.tokenize(self.serialize)
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

    def self.from_attribute(a)
      return self.new(
        id: a.id, value: a.fqn_label, label: a.name, type: Suma::Eligibility::Expression::Tokenizer::VARIABLE,
      )
    end
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
    OPERATOR_VALUES = OPERATOR_TOKENS.map(&:value)

    class Warning < Suma::TypedStruct
      attr_reader :index, :message, :value

      def initialize(index, message, value)
        super(index:, message:, value:)
      end

      def to_s
        v = self.value.empty? ? "" : " #{self.value}"
        "#{self.message}: (#{self.index})#{v}"
      end
    end

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
        warnings = []
        self._detokenize(tokens, warnings, ser)
        return Detokenization.new(serialized: ser, warnings:)
      end

      # @param tokens [Array<Suma::Eligibility::Expression::Token>]
      # @param warnings [Array<Suma::Eligibility::Expression::Tokenizer::Warning>]
      # @param serialized [Hash]
      def _detokenize(tokens, warnings, serialized)
        return nil if tokens.empty?

        # Handle the degenerative case of a single attribute node
        if tokens.length === 1 && (t = tokens[0]).type == VARIABLE
          serialized.merge!(attr: t.id, name: t.label, fqn: t.value)
          return nil
        end

        node_stack = [serialized]
        depth = 0
        last_open_paren = nil
        (0...tokens.length).each do |i|
          t = tokens[i]
          # Guard these fatal warnings
          unless [PAREN, OPERATOR, VARIABLE].include?(t.type)
            warnings << Warning.new(i, "invalid type", t.type)
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
          if t.type == PAREN && !"()".include?(t.id)
            warnings << Warning.new(i, "invalid parenthesis id", t.id)
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
          if t.type == OPERATOR && !OPERATOR_VALUES.include?(t.id)
            warnings << Warning.new(i, "invalid operator id", t.id)
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
          prev = i.zero? ? nil : tokens[i - 1]
          nxt = tokens[i + 1]
          if t.id == "("
            depth += 1
            last_open_paren = i
          elsif t.id == ")"
            depth -= 1
            if depth.negative?
              # Syntax issues are fatal
              warnings << Warning.new(i, "unmatched closing parenthesis", "")
              return # rubocop:disable Lint/NonLocalExitFromIterator
            end
          end
          if (t.type == OPERATOR) && (!prev || prev.value == "(" || prev.type == OPERATOR)
            warnings << Warning.new(i, "cannot appear here", t.value)
            # warnings << Warning.new(i, "operator cannot terminate expression", t.value) unless nxt
          end
          if (t.type == VARIABLE) && prev && (prev.type == VARIABLE || prev.value == ")")
            warnings << Warning.new(i, "operator required before variable", t.value)
          end
          if t.id == "("
            warnings << Warning.new(i, "empty parentheses are not allowed", "") if nxt && nxt.value === ")"
            if prev && (prev.type == VARIABLE || prev.value == ")")
              warnings << Warning.new(i, "missing operator before (", "")
            end
          end
          if (t.id == ")") && prev && prev.type == OPERATOR
            warnings << Warning.new(i, "operator before ) is invalid", "")
          end

          # Detokenize tokens into serializable form.
          # The following token strings would yield structures:
          # x -> {attr: <x.id>}
          # (x) -> {attr: <x.id>}
          # x AND y -> {left: {attr: <x.id>}, op: AND, right: {attr: <y.id>}}
          if t.type == OPERATOR
            # Update the top-level node.
            node_stack.last[:op] = t.value
          elsif t.id == ")"
            # We're closing a group; figure out whether it should go to left or right of the outer group.
            node = node_stack.pop
            head = node_stack.last
            key = head.key?(:left) ? :right : :left
            head[key] = node
          elsif t.id == "("
            # We're opening a new group, so push a new node.
            node = {}
            node_stack.push(node)
          else
            # This is a variable node, assign it to left or right.
            head = node_stack.last
            key = head.key?(:left) ? :right : :left
            head[key] = {attr: t.id, name: t.label, fqn: t.value}
          end
        end

        warnings << Warning.new(last_open_paren, "unmatched opening parenthesis", "") if depth != 0
        last = tokens[tokens.length - 1]
        warnings << Warning.new(tokens.length - 1, "expression cannot end with operator", last.value) if
          last.type == OPERATOR
      end
    end
  end
end
