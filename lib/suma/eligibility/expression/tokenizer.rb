# frozen_string_literal: true

require "suma/eligibility/expression"

class Suma::Eligibility::Expression::Tokenizer
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
    include Suma::Eligibility::Expression::Constants
    include Suma::Eligibility::Expression::Serializer::Nodes

    # Tokenize a serialized expression (see +Suma::Eligibility::Expression#serialize+).
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
      result << Token.constant(node.op, OPERATOR) if node.is_a?(BinaryNode)
      result.concat(self.tokenize(node.right, depth: depth + 1)) if node[:right]
      result << TOK_PAREN_CLOSE if depth.positive?
      return result
    end

    # Parse a tokenized expression into one that can be passed to +Suma::Eligibility::Expression#deserialize+.
    # @param tokens [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    # @return [Detokenization]
    def detokenize(tokens)
      t = self.new(tokens)
      node = t.parse
      return Detokenization.new(serialized: node, warnings: t.warnings)
    end

    # @param tokens [Array<Suma::Eligibility::Expression::Tokenizer::Token>]
    # @param warnings [Array<Suma::Eligibility::Expression::Tokenizer::Warning>]
    # @param serialized [Suma::Eligibility::Expression::Serializer::Node]
    def _detokenize(tokens, warnings, serialized)
      # rubocop:disable Lint/DuplicateBranch

      return nil if tokens.empty?

      # Handle the degenerative case of a single attribute node
      if tokens.length === 1 && (t = tokens[0]).type == VARIABLE
        serialized.merge!(attr: t.id, name: t.label, fqn: t.value)
        return nil
      end

      serializer = Suma::Eligibility::Expression::Serializer

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
        if t.binary? && (!prev || prev.value == "(" || prev.type == OPERATOR)
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
          # Operators can either:
          # - Update the top level node (unary and binary both work the same in that sense)
          # - Establish a new node, if the head node already has an operator.
          #   That is, "NOT NOT x" needs to create two nodes, not set the operator twice.
          if node_stack.last[:op]
            # Add a new node
            node = serializer.operator_hash(t.id)
            node_stack.push(node)
          else
            # Update the top level node
            node_stack.last[:op] = t.id
          end
        elsif t.id == ")"
          # We're closing a group; figure out whether it should go to left or right of the outer group.
          # If there is already a 'left', it must go in the right;
          # but if there is no left, check if we know we're already working with a binary operator;
          # if we are, that means we must set the right node, like 'OR (X)'.
          node = node_stack.pop
          head = node_stack.last
          if head.key?(:left)
            head[:right] = node
          elsif binary_hash?(head)
            head[:right] = node
          else
            head[:left] = node
          end
        elsif t.id == "("
          # We're opening a new group, so push a new node.
          node = {}
          node_stack.push(node)
        else
          # Suma.assert { t.type == VARIABLE }
          # This is a variable node. This can either:
          # - Begin a binary operation (left)
          # - End a binary operation (right)
          # - End a unary operation (left)
          ahash = serializer::AttributeNode.new(id: t.id, name: t.label, fqn: t.value)
          head = node_stack.last
          # First let's check if the top of the stack is already 'finished';
          # that is, a unary node with an operator, a binary node with two,
          # or another variable node.
          # If they are, we need to add to the stack, not update.
          head_closed = head.filled?
          if head_closed
            node_stack.push(ahash)
          elsif self.unary_hash?(head)
            # This is a unary op like NOT, this is the operand for it.
            head[:left] = ahash
          elsif !head.key?(:op)
            # One of two situations:
            # 1) don't know what type of node this is yet;
            #    it could be blank, like if we're evaluating X in 'X OR Y',
            #    In this case, always assign to left.
            # 2) it's the second operand of a binary operator.
            #    In this case, always assign to the right, since the left must have been assigned (or skipped)
            #    to find the binary operator in the first place.
            head[:left] = ahash
          else
            head[:right] = ahash
          end
        end
      end

      warnings << Warning.new(last_open_paren, "unmatched opening parenthesis", "") if depth != 0
      last = tokens[tokens.length - 1]
      warnings << Warning.new(tokens.length - 1, "expression cannot end with operator", last.value) if
        last.type == OPERATOR

      # rubocop:enable Lint/DuplicateBranch
    end
  end

  include Suma::Eligibility::Expression::Serializer::Nodes

  attr_reader :warnings

  def initialize(tokens)
    @root = BinaryNode.new(left: nil, right: nil, op: nil)
    @warnings = []
    @tokens = tokens
  end

  # @return Suma::Eligibility::Expression::Serializer::Node
  def parse
    # rubocop:disable Lint/DuplicateBranch
    tokens = @tokens
    warnings = @warnings

    return nil if tokens.empty?

    # Handle the degenerative case of a single attribute node
    if tokens.length === 1 && (t = tokens[0]).type == VARIABLE
      @root = AttributeNode.new(attr: t.id, name: t.label, fqn: t.value)
      return
    end

    node_stack = [@root]
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
      if t.binary? && (!prev || prev.value == "(" || prev.type == OPERATOR)
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
        # Operators can either:
        # - Update the top level node (unary and binary both work the same in that sense)
        # - Establish a new node, if the head node already has an operator.
        #   That is, "NOT NOT x" needs to create two nodes, not set the operator twice.
        # if node_stack.last[:op]
        # Add a new node
        # node = serializer.operator_hash(t.id)
        # node_stack.push(node)
        # else
        # Update the top level node
        node_stack.last[:op] = t.id
        # end
      elsif t.id == ")"
        # We're closing a group; figure out whether it should go to left or right of the outer group.
        # If there is already a 'left', it must go in the right;
        # but if there is no left, check if we know we're already working with a binary operator;
        # if we are, that means we must set the right node, like 'OR (X)'.
        node = node_stack.pop
        head = node_stack.last

        if head.key?(:left)
          head[:right] = node
        elsif binary_hash?(head)
          head[:right] = node
        else
          head[:left] = node
        end
      elsif t.id == "("
        # We're opening a new group, so push a new node.
        node = {}
        node_stack.push(node)
      else
        # Suma.assert { t.type == VARIABLE }
        # This is a variable node. This can either:
        # - Begin a binary operation (left)
        # - End a binary operation (right)
        # - End a unary operation (left)
        ahash = serializer::AttributeNode.new(id: t.id, name: t.label, fqn: t.value)
        head = node_stack.last
        # First let's check if the top of the stack is already 'finished';
        # that is, a unary node with an operator, a binary node with two,
        # or another variable node.
        # If they are, we need to add to the stack, not update.
        head_closed = head.filled?
        if head_closed
          node_stack.push(ahash)
        elsif self.unary_hash?(head)
          # This is a unary op like NOT, this is the operand for it.
          head[:left] = ahash
        elsif !head.key?(:op)
          # One of two situations:
          # 1) don't know what type of node this is yet;
          #    it could be blank, like if we're evaluating X in 'X OR Y',
          #    In this case, always assign to left.
          # 2) it's the second operand of a binary operator.
          #    In this case, always assign to the right, since the left must have been assigned (or skipped)
          #    to find the binary operator in the first place.
          head[:left] = ahash
        else
          head[:right] = ahash
        end
      end
    end

    warnings << Warning.new(last_open_paren, "unmatched opening parenthesis", "") if depth != 0
    last = tokens[tokens.length - 1]
    warnings << Warning.new(tokens.length - 1, "expression cannot end with operator", last.value) if
      last.type == OPERATOR

    # rubocop:enable Lint/DuplicateBranch
  end
end
