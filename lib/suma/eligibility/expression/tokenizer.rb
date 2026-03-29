# frozen_string_literal: true

require "suma/eligibility/expression"

module Suma::Eligibility::Expression::Tokenizer
  include Suma::Eligibility::Expression::Constants

  PAREN = :paren
  OPERATOR = :operator
  VARIABLE = :variable
  TYPES = [PAREN, OPERATOR, VARIABLE].freeze

  class Token < Suma::TypedStruct
    attr_reader :id, :value, :label, :type

    def initialize(**kwargs)
      kwargs[:type] = kwargs[:type].to_sym if kwargs[:type]
      super
    end

    def self.constant(s, type) = self.new(id: s, value: s, label: s, type:)

    def self.from_attribute(a)
      return self.new(
        id: a.id, value: a.fqn_label, label: a.name, type: VARIABLE,
      )
    end
  end

  TOK_PAREN_OPEN = Token.constant("(", PAREN)
  TOK_PAREN_CLOSE = Token.constant(")", PAREN)
  PAREN_TOKENS = [TOK_PAREN_OPEN, TOK_PAREN_CLOSE].freeze

  TOK_OP_AND = Token.constant(AND, OPERATOR)
  TOK_OP_OR = Token.constant(OR, OPERATOR)
  TOK_OP_NOT = Token.constant(NOT, OPERATOR)

  UNARY_OP_TOKENS = [TOK_OP_NOT].freeze
  BINARY_OP_TOKENS = [TOK_OP_AND, TOK_OP_OR].freeze
  OPERATOR_TOKENS = BINARY_OP_TOKENS + UNARY_OP_TOKENS
  VALID_OPERATOR_VALUES = OPERATOR_TOKENS.map(&:id)

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
    # @return [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    def tokenize(expr, depth: 0)
      if expr[:attr]
        return [
          Token.new(
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
      result << Token.constant("AND", OPERATOR) if expr[:op] == "AND"
      result << Token.constant("OR", OPERATOR) if expr[:op] == "OR"
      result.concat(self.tokenize(expr[:right], depth: depth + 1)) if expr[:right]
      result << TOK_PAREN_CLOSE if depth.positive?
      return result
    end

    # Parse a tokenized expression into one that can be passed to +Suma::Eligibility::Expression#deserialize+.
    # @param tokens [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    # @return [Detokenization]
    def detokenize(tokens)
      ser = {}
      warnings = []
      self._detokenize(tokens, warnings, ser)
      return Detokenization.new(serialized: ser, warnings:)
    end

    # @param tokens [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
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
        if t.type == OPERATOR && !VALID_OPERATOR_VALUES.include?(t.id)
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
        warnings << Warning.new(i, "operator before ) is invalid", "") if (t.id == ")") && prev && prev.type == OPERATOR

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
