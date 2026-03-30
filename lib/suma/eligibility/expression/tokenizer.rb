# frozen_string_literal: true

require "suma/eligibility/expression"

module Suma::Eligibility::Expression::Tokenizer
  include Suma::Eligibility::Expression::Constants

  PAREN = :paren
  OPERATOR = :operator
  VARIABLE = :variable
  TYPES = [PAREN, OPERATOR, VARIABLE].freeze

  class Token
    include Suma::Eligibility::Expression::Constants

    def self.constant(s, type) = self.new(id: s, value: s, label: s, type:)

    def self.from_attribute(a)
      return self.new(
        id: a.id, value: a.fqn_label, label: a.name, type: VARIABLE,
      )
    end

    attr_reader :id, :value, :label, :type

    def initialize(id:, value:, label:, type:)
      @id = id
      @value = value
      @label = label
      @type = type.to_sym
    end

    def binary? = self.type == OPERATOR && BINARY_OPS.include?(self.id)
    def unary? = self.type == OPERATOR && UNARY_OPS.include?(self.id)
    def variable? = self.type == VARIABLE

    def to_h = {id:, value:, label:, type:}
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

  class Detokenization
    # Detokenized node, or nil if an error.
    # @return [Suma::Eligibility::Expression::Serializer::Nodes::Node,nil]
    attr_accessor :node

    # Error due to a parse error.
    # @return [Integer,nil]
    attr_accessor :error_index
    # @return [String,nil]
    attr_accessor :error_reason
    # @return [String,nil]
    attr_accessor :error_value
    # @return [String,nil]
    attr_accessor :error_message

    def to_h = {node:, error_index:, error_value:, error_reason:, error_message:}
  end

  class << self
    include Suma::Eligibility::Expression::Constants
    include Suma::Eligibility::Expression::Serializer::Nodes

    # Tokenize a serialized expression (see +Suma::Eligibility::Expression::Serializer+).
    # @param node [Hash,Suma::Eligibility::Expression::Serializer::Node]
    # @return [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    def tokenize(node, depth: 0)
      node = Node.from_h(node)
      if node.is_a?(AttributeNode)
        return [
          Token.new(
            id: node.attr,
            value: node.fqn,
            label: node.name,
            type: VARIABLE,
          ),
        ]
      end
      result = []
      result << TOK_PAREN_OPEN if depth.positive?
      result << Token.constant(node.op, OPERATOR) if node.is_a?(UnaryNode)
      result.concat(self.tokenize(node.left, depth: depth + 1)) if node.left
      if node.is_a?(BinaryNode)
        result << Token.constant(node.op, OPERATOR)
        result.concat(self.tokenize(node.right, depth: depth + 1)) if node.right
      end
      result << TOK_PAREN_CLOSE if depth.positive?
      return result
    end

    # Parse a tokenized expression into one that
    # can be passed to +Suma::Eligibility::Expression::Serializer.deserialize+.
    # @param tokens [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    # @return [Detokenization]
    def detokenize(tokens)
      t = ExpressionParser.new(tokens)
      r = Detokenization.new
      begin
        r.node = t.parse
      rescue ParseError => e
        r.error_index = e.index
        r.error_reason = e.reason
        r.error_value = e.value
        r.error_message = e.message
      end
      return r
    end
  end

  class ParseError < StandardError
    attr_reader :index, :reason, :value

    def initialize(index, reason, value=nil)
      @index = index
      @reason = reason
      @value = value
      v = (@value || '').empty? ? "" : " #{@value}"
      super("#{@reason}: (#{@index})#{v}")
    end
  end

  class ExpressionParser
    include Suma::Eligibility::Expression::Serializer::Nodes

    INFIX_BP = { "AND" => 10, "OR" => 5 }.freeze

    # @param tokens [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    # @return [Suma::Eligibility::Expression::Serializer::Node]
    def parse
      node = parse_expr(0)
      raise ParseError.new(@pos, "unexpected token", @tokens[@pos].value) if @pos < @tokens.size
      return node
    end

    private

    # @return [Suma::Eligibility::Expression::Serializer::Node]
    def parse_expr(min_bp)
      left = self.parse_prefix

      loop do
        op = self.peek_token
        raise ParseError.new(@pos, "not a binary operator", op.id) if
          op&.type == OPERATOR && !op.binary?

        break unless op&.type == OPERATOR && INFIX_BP[op.id]
        break if INFIX_BP[op.id] <= min_bp

        self.consume_token
        right = self.parse_expr(INFIX_BP[op.id])
        left = BinaryNode.new(left:, op: op.id, right:)
      end

      return left
    end

    # @return [Suma::Eligibility::Expression::Serializer::Node]
    def parse_prefix
      t = self.peek_token
      raise ParseError.new(@pos-1, "unexpected end of input", self.prev_token&.value) unless t

      case t.type
        when PAREN
          raise ParseError.new(@pos, "invalid parenthesis id", t.id) unless '()'.include?(t.id)
          raise ParseError.new(@pos, "unexpected )") if t.id == ")"
          self.consume_token
          inner = self.parse_expr(0)
          raise ParseError.new(@pos, "expected )", "") unless self.peek_token&.id == ")"
          self.consume_token
          return inner
        when VARIABLE
          self.consume_token
          return AttributeNode.new(attr: t.id, name: t.label, fqn: t.value)
        when OPERATOR
          raise ParseError.new(@pos, "not a unary operator", t.id) unless t.unary?
          self.consume_token
          UnaryNode.new(left: parse_expr(15), op: t.id)

        else
          raise ParseError.new(@pos, "invalid type", t.type)
      end
    end

    # @return [Suma::Eligibility::Expression::Tokenizer::Token]
    def peek_token = @tokens[@pos]
    # @return [Suma::Eligibility::Expression::Tokenizer::Token,nil]
    def prev_token = @pos.zero? ? nil : @tokens[@pos-1]
    # @return [Suma::Eligibility::Expression::Tokenizer::Token]
    def next_token = @tokens[@pos+1]

    def consume_token = @tokens[@pos].tap { @pos += 1 }
  end
end
