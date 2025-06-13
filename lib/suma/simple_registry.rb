# frozen_string_literal: true

module Suma::SimpleRegistry
  class Unregistered < KeyError; end

  def registry = @registry ||= {}

  # Override the registry key used in +registry_lookup!+.
  attr_accessor :registry_override

  def register(key, value)
    self.registry[key.to_s] = value
  end

  def registry_lookup!(key)
    key = self.registry_override if self.registry_override
    r = self.registry[key.to_s]
    raise Unregistered, "#{key} not in registry: #{self.registry.keys}" if r.nil?
    return r
  end

  def registry_create!(key, *)
    x = self.registry_lookup!(key)
    return x.new(*)
  end
end
