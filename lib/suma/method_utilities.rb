# frozen_string_literal: true

require "suma" unless defined?(Suma)

# A collection of methods for declaring other methods.
#
#   class MyClass
#       extend Suma::MethodUtilities
#
#       singleton_attr_accessor :types
#       singleton_method_alias :kinds, :types
#   end
#
#   MyClass.types = [:pheno, :proto, :stereo]
#   MyClass.kinds # => [:pheno, :proto, :stereo]
#
module Suma::MethodUtilities
  # Creates instance variables and corresponding methods that return their
  # values for each of the specified +symbols+ in the singleton of the
  # declaring object (e.g., class instance variables and methods if declared
  # in a Class).
  def singleton_attr_reader(*symbols)
    singleton_class.instance_exec(symbols) do |attrs|
      attr_reader(*attrs)
    end
  end

  # Create instance variables and corresponding methods that return
  # true or false values for each of the specified +symbols+ in the singleton
  # of the declaring object.
  def singleton_predicate_reader(*symbols)
    singleton_class.extend(Suma::MethodUtilities)
    singleton_class.attr_predicate(*symbols)
  end

  # Creates methods that allow assignment to the attributes of the singleton
  # of the declaring object that correspond to the specified +symbols+.
  def singleton_attr_writer(*symbols)
    singleton_class.instance_exec(symbols) do |attrs|
      attr_writer(*attrs)
    end
  end

  # Creates readers and writers that allow assignment to the attributes of
  # the singleton of the declaring object that correspond to the specified
  # +symbols+.
  def singleton_attr_accessor(*symbols)
    symbols.each do |sym|
      singleton_class.__send__(:attr_accessor, sym)
    end
  end

  # Create predicate methods and writers that allow assignment to the attributes
  # of the singleton of the declaring object that correspond to the specified
  # +symbols+.
  def singleton_predicate_accessor(*symbols)
    singleton_class.extend(Suma::MethodUtilities)
    singleton_class.attr_predicate_accessor(*symbols)
  end

  # Creates an alias for the +original+ method named +newname+.
  def singleton_method_alias(newname, original)
    singleton_class.__send__(:alias_method, newname, original)
  end

  # Create a reader in the form of a predicate for the given +attrname+.
  def attr_predicate(attrname)
    attrname = attrname.to_s.chomp("?")
    define_method(:"#{attrname}?") do
      instance_variable_get(:"@#{attrname}") ? true : false
    end
  end

  # Create a reader in the form of a predicate for the given +attrname+
  # as well as a regular writer method.
  def attr_predicate_accessor(attrname)
    attrname = attrname.to_s.chomp("?")
    attr_writer(attrname)

    attr_predicate(attrname)
  end

  # Return true if the timestamp named by the given attribute is set.
  #
  # @param o [Object]
  # @param attrname [Symbol]
  # @return [Boolean]
  module_function def timestamp_set?(o, attrname) = o.send(attrname) ? true : false

  # Set the timestamp with given name.
  #
  # @param o [Object]
  # @param attrname [Symbol]
  # @param v [Time,Boolean] If false, set to nil. If true, set to now if not already set.
  #   To stomp the current value, you can use Time.now explicitly.
  # @return [Boolean]
  module_function def timestamp_set(o, attrname, v)
    setter = :"#{attrname}="
    if v == true
      o.send(setter, o.send(attrname) || Time.now)
    elsif v == false
      o.send(setter, nil)
    else
      o.send(setter, v)
    end
  end

  # Return the first association with a non-nil value.
  # This is usually the ORM side of a Sequel.unambiguous_constraint.
  #
  # @param o [Object]
  # @param assocs [Array<Symbol>]
  # @return [Sequel::Model]
  module_function def unambiguous_association(o, assocs)
    assocs.each do |assoc|
      v = o.send(assoc)
      return v unless v.nil?
    end
    return nil
  end

  # Set the relevant association field by finding the first with the same type as v,
  # and assigning to it. All other assocs get nil assigned.
  # If v is not a supported type, raise a TypeError.
  #
  # @param o [Object]
  # @param assocs [Array<Symbol>]
  # @param v [Sequel::Model]
  module_function def set_ambiguous_association(o, assocs, v)
    if v.nil?
      assocs.each do |assoc|
        o.send("#{assoc}=", nil)
      end
      return
    end
    assocs.each do |assoc|
      details = o.class.association_reflections[assoc]
      type_match = details[:class_name] == v.class.name
      next unless type_match
      assocs.each do |other|
        next if other == assoc
        o.send("#{other}=", nil)
      end
      o.send("#{assoc}=", v)
      # rubocop:disable Lint/NonLocalExitFromIterator
      return
      # rubocop:enable Lint/NonLocalExitFromIterator
    end
    raise TypeError, "invalid association type: #{v.class}(#{v})"
  end
end
