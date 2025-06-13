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
    kvps = self._accessors.map { |m| "#{m}: #{self.send(m).inspect}" }.join(", ")
    return "#{self.class.name}(#{kvps})"
  end

  private def _accessors
    return @_accessors ||= begin
      @_accessors = self.public_methods - Suma::TypedStruct._cached_base_methods
      @_accessors.reject! { |m| m.to_s.end_with?("=") || self.method(m).arity.nonzero? }
      @_accessors.sort!
      @_accessors
    end
  end

  def as_json = self._accessors.to_h { |k| [k, self[k]] }.as_json
end
