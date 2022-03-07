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
  end
end
