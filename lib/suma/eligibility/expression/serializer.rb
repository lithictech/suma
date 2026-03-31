# frozen_string_literal: true

require "suma/eligibility/expression"

module Suma::Eligibility::Expression::Serializer
  # Mixin for easy aliasing.
  module Nodes
    # Represents a node in the structured serialization form.
    # Can be rendered to and parsed from a hash.
    # There are different concrete node forms,
    # which form different structures on the tree:
    # - Attributes points to attributes, which are combined logically by
    # - Unary operations
    # - and Binary operations.
    class Node
      # @return [Hash]
      def to_h = self._to_h.delete_if { |_k, v| v.nil? }

      # @return [Hash]
      def _to_h = raise NotImplementedError

      def filled? = raise NotImplementedError

      def self.from_h(h)
        return nil if h.nil?
        return h if h.is_a?(self)
        return AttributeNode.new(**h) if h[:attr]
        if Suma::Eligibility::Expression::UNARY_OPS.include?(h[:op])
          n = UnaryNode.new(**h)
          n.left = self.from_h(n.left)
        else
          n = BinaryNode.new(**h)
          n.left = self.from_h(n.left)
          n.right = self.from_h(n.right)
        end
        return n
      end
    end

    class AttributeNode < Node
      attr_accessor :attr, :name, :fqn

      def initialize(attr:, name: nil, fqn: nil)
        super()
        @attr = attr
        @name = name
        @fqn = fqn
      end

      def _to_h = {attr: @attr, name: @name, fqn: @fqn}
      def filled? = true

      def self.from_attribute(a) = self.new(attr: a.id, name: a.name, fqn: a.fqn_label)
    end

    class BinaryNode < Node
      attr_accessor :left, :right, :op

      def initialize(left: nil, right: nil, op: nil)
        super()
        @left = left
        @right = right
        @op = op
      end

      def _to_h = {left: @left&.to_h, op: @op, right: @right&.to_h}

      def filled? = self.left && self.right
    end

    class UnaryNode < Node
      attr_accessor :left, :op

      def initialize(op:, left: nil)
        super()
        @left = left
        @op = op
      end

      def _to_h = {left: @left&.to_h, op: @op}

      def filled? = self.left
    end
  end

  include Nodes

  class << self
    include Suma::Eligibility::Expression::Constants
    include Nodes

    # Return a serializable object representing the expression.
    # Can be deserialized using deserialize.
    # @param [Suma::Eligibility::Expression]
    # @return [Node]
    def serialize(e)
      return nil if e.nil?
      return AttributeNode.from_attribute(e.attribute) if e.attribute?
      return UnaryNode.new(left: self.serialize(e.left), op: e.operator) if e.unary?
      return BinaryNode.new(left: self.serialize(e.left), op: e.operator, right: self.serialize(e.right))
    end

    # Deserialize an instance from a serialized version.
    # If any invalid attribute IDs are used, they are ignored,
    # and the subexpression will be empty.
    # @param node [Node,Hash]
    # @return [Suma::Eligibility::Expression,nil]
    def deserialize(node)
      Suma::Eligibility::Expression.db.transaction do
        r = _deserialize(node)
        # If we can't deserialize anything (invalid attr at the root level, or something like that),
        # just return an empty expression.
        r ||= Suma::Eligibility::Expression.create_empty
        return r
      end
    end

    def _deserialize(node)
      return nil if node.nil?
      node = Node.from_h(node) if node.is_a?(Hash)
      if node.is_a?(AttributeNode)
        attribute = Suma::Eligibility::Attribute[node.attr]
        return nil if attribute.nil?
        return Suma::Eligibility::Expression.create(type: ATTRIBUTE, attribute:)
      end
      h = {}
      h[:left] = _deserialize(node.left) if node.respond_to?(:left)
      h[:right] = _deserialize(node.right) if node.respond_to?(:right)
      h[:operator] = node.op || AND
      h[:type] = UNARY_OPS.include?(node.op) ? UNARY : BINARY
      return Suma::Eligibility::Expression.create(h)
    end
  end
end
