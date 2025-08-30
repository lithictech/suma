# frozen_string_literal: true

module Suma::SimpleRegistry
  class Unregistered < KeyError; end

  protected def registry = @registry ||= {}
  def registered_keys = self.registry.keys

  # Override the registry key used in +registry_lookup!+.
  attr_accessor :registry_override

  def register(key, value, *args, **kwargs)
    self.registry[key.to_s] = [value, args, kwargs]
  end

  def registry_lookup_args!(key)
    key = self.registry_override if self.registry_override
    r = self.registry[key.to_s]
    raise Unregistered, "key cannot be blank" if key.blank?
    raise Unregistered, "#{key} not in registry: #{self.registry.keys}" if r.nil?
    return r
  end

  def registry_lookup!(key)
    return self.registry_lookup_args!(key).first
  end

  def registry_create!(key, *more_args, **more_kwargs)
    cls, args, kwargs = self.registry_lookup_args!(key)
    args += more_args
    kwargs = kwargs.merge(more_kwargs)
    return cls.new(*args, **kwargs)
  end

  def registry_each
    return enum_for(:registry_each) unless block_given?

    self.registry.each_key do |key|
      yield self.registry_create!(key)
    end
  end
end
