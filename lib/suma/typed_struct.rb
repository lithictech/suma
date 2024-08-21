# frozen_string_literal: true

class Suma::TypedStruct
  class << self
    def _cached_base_methods = @_cached_base_methods ||= Suma::TypedStruct.new.public_methods
  end
  def initialize(**kwargs)
    self._defaults.merge(kwargs).each do |k, v|
      raise TypeError, "invalid struct field #{k}" unless self.respond_to?(k)
      self.instance_variable_set(:"@#{k}", v)
    end
  end

  def _defaults
    return {}
  end

  def [](k)
    return self.send(k)
  end

  def inspect
    methods_to_keep = self.public_methods - Suma::TypedStruct._cached_base_methods
    methods_to_keep.reject! { |m| m.to_s.end_with?("=") || self.method(m).arity.nonzero? }
    methods_to_keep.sort!
    kvps = methods_to_keep.map { |m| "#{m}: #{self.send(m).inspect}" }.join(", ")
    return "#{self.class.name}(#{kvps})"
  end
end
