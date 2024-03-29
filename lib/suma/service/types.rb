# frozen_string_literal: true

require "grape"

module Suma::Service::Types
  def self.included(ctx)
    ctx.const_set(:NormalizedEmail, NormalizedEmail)
    ctx.const_set(:NormalizedPhone, NormalizedPhone)
    ctx.const_set(:CommaSepArray, CommaSepArray)
  end

  class NormalizedEmail
    def self.parse(value)
      return value.downcase.strip
    end
  end

  class NormalizedPhone
    def self.parse(value)
      return Suma::PhoneNumber::US.normalize(value)
    end
  end

  class CommaSepArray
    def self.parse(value)
      return value if value.respond_to?(:to_ary)
      return value.split(",").map(&:strip)
    end

    def self.[](coerce)
      return self.new(coerce)
    end

    def initialize(coerce)
      if coerce.is_a?(Class)
        # Support passing CommaSepArray[Float], etc.
        # Float is both a class 'Float' but also a `def` on Kernel.
        coerce = Kernel.method(coerce.name)
      end
      @coerce = coerce
    end

    def parse(value)
      arr = self.class.parse(value)
      return arr.map { |x| @coerce.call(x) }
    end
  end

  class DecimalLocation
    def self.parse(value)
      arr = value.respond_to?(:to_ary) ? value : value.split(",").map(&:strip)
      return arr.map { |v| BigDecimal(v) }
    end
  end

  class IntegerLocation
    def self.parse(value)
      arr = value.respond_to?(:to_ary) ? value : value.split(",").map(&:strip)
      return arr.map { |v| Integer(v) }
    end
  end
end
