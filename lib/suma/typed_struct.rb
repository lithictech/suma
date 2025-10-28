# frozen_string_literal: true

# Similar to a Ruby struct or Data, but with some better behaviors
# for our preferred use patterns:
# - Caller chooses mutable/immutable (attr_accessor vs. attr_reader)
# - Works with type hinting (can document attr_ methods).
# - Good inspect and as_json.
# - Hash or attribute lookup (x[:z] and x.z both work).
# - Defaults via :_defaults method.
# - Define required/optional params (:requires method).
class Suma::TypedStruct
  class << self
    # Return an array of accessor methods unique to this class and base classes, but NOT the base typed struct.
    # "Accessors" are defined as methods with an arity of 0.
    def _accessors
      return @_accessors if @_accessors
      @_accessors = []
      @_accessors_without_writers = []
      methods = Set.new(self.instance_methods - Suma::TypedStruct.instance_methods)
      methods.each do |m|
        next unless self.instance_method(m).arity.zero?
        has_setter = methods.include?(:"#{m}=")
        if has_setter
          @_accessors << m
        elsif !m.to_s.end_with?("=")
          @_accessors << m
          @_accessors_without_writers << m
        end
      end
      @_accessors.sort!
      @_accessors_without_writers.sort!
      @_accessors
    end

    def _accessors_without_writers
      self._accessors
      return @_accessors_without_writers
    end

    # Mark an attribute as required. If called with no args,
    # all read-only attributes (attr_reader) are required.
    def requires(*args, all: false)
      args = self._accessors_without_writers if all
      @_requires ||= Set.new([])
      args.each { |a| @_requires.add(a) }
    end

    # Raise if is missing any required fields.
    def _check_required!(kw)
      return if @_requires.nil?

      missing = []
      @_requires.each do |sym|
        missing << sym unless kw.include?(sym)
      end
      return if missing.empty?
      raise ArgumentError, "missing required fields: #{missing.join(', ')}"
    end
  end

  def initialize(**kwargs)
    kw = self._defaults.merge(kwargs)
    self.class._check_required!(kw)
    kw.each do |k, v|
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
    kvps = self.class._accessors.map { |m| "#{m}: #{self.send(m).inspect}" }.join(", ")
    return "#{self.class.name}(#{kvps})"
  end

  def as_json = self.class._accessors.to_h { |k| [k, self[k]] }.as_json
end
