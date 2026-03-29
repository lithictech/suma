# frozen_string_literal: true

require "suma/eligibility/expression"

module Suma::Eligibility::Expression::Serializer
  class << self
    include Suma::Eligibility::Expression::Constants

    # Return a serializable object representing the expression.
    # Can be deserialized using deserialize.
    # @param [Suma::Eligibility::Expression]
    # @return [Hash]
    def serialize(e)
      return self.hash_from_attr(e) if e.attribute?
      h = {}
      h[:left] = e.left.serialize if e.left
      h[:right] = e.right.serialize if e.right
      h[:op] = e.operator
      return h
    end

    def attr_hash(id:, name:, fqn:) = {attr: id, name:, fqn:}
    def hash_from_attr(a) = self.attr_hash(id: a.id, name: a.name, fqn: a.fqn_label)
    def operator_hash(op, left=nil, right=nil) = {left:, op:, right:}

    # Deserialize an instance from a serialized version.
    # If any invalid attribute IDs are used, they are ignored,
    # and the subexpression will be empty.
    # @param arg [Hash]
    # @return [Suma::Eligibility::Expression,nil]
    def deserialize(arg)
      Suma::Eligibility::Expression.db.transaction do
        r = _deserialize(arg)
        # If we can't deserialize anything (invalid attr at the root level, or something like that),
        # just return an empty expression.
        r ||= Suma::Eligibility::Expression.create_empty
        return r
      end
    end

    def _deserialize(arg)
      return nil if arg.nil?
      if arg[:attr]
        attribute = Suma::Eligibility::Attribute[arg[:attr]]
        return nil if attribute.nil?
        return Suma::Eligibility::Expression.create(type: ATTRIBUTE, attribute:)
      end
      h = {}
      h[:left] = _deserialize(arg[:left]) if arg[:left]
      h[:right] = _deserialize(arg[:right]) if arg[:right]
      h[:operator] = arg[:op] || AND
      h[:type] = UNARY_OPS.include?(h[:operator]) ? UNARY : BINARY
      return Suma::Eligibility::Expression.create(h)
    end
  end
end
