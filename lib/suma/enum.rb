# frozen_string_literal: true

require "suma/typed_struct"

# Factory + central registry for backend enums that need to be mirrored into TypeScript.
# Call Suma::Enum.define once per enum, then reference the resulting constant in @return tags.
#
#   module MyClass
#     MyEnum = Suma::Enum.define(self, :MyEnum, [:x, :y])
#   end
#   puts MyClass::MyEnum.values
#   => [:x, :y]
#
module Suma::Enum
  class Definition < Suma::TypedStruct
    attr_reader :name, :fqn, :host, :values, :module
  end

  # Registry of all defined enums.
  # @return {Array<Definition>}
  def self.registry = (@registry ||= [])

  # @param host [Module,Class] Used to generate the FQN for the enum.
  #   The caller is responsible for assigning the return of this method to a constant,
  #   to aid type completion.
  # @param const_name [Symbol] Name of the const, set on the host.
  #   Must be usable as a constant name, like MyEnum, and must be unique across all enums.
  # @param values [Array<Symbol>] allowed values, in canonical order.
  # @return [Module]
  def self.define(host, const_name, values, registry: nil)
    registry ||= self.registry
    values = values.freeze

    mod = Module.new do
      const_set(:NAME, const_name)
      const_set(:VALUES, values)
      values.each do |v|
        v2 = v
        define_singleton_method(v2) { v2 }
      end
    end

    host_name = host.respond_to?(:name) ? host.name : host.to_s
    registry << Definition.new(name: const_name, fqn: "#{host_name}::#{const_name}", host:, values:, module: mod)
    return mod
  end
end
