# frozen_string_literal: true

module Suma::SimpleRegistry
  class Unregistered < KeyError; end

  def registry
    @registry ||= {}
  end

  def register(key, value)
    self.registry[key.to_s] = value
  end

  def registry_lookup!(key)
    r = self.registry[key.to_s]
    raise Unregistered, "#{key} not in registry: #{self.registry.keys}" if r.nil?
    return r
  end

  def registry_create!(key, *args)
    x = self.registry_lookup!(key)
    return x.new(*args)
  end
end
