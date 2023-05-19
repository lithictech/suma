# frozen_string_literal: true

module Suma::Mobility::VendorAdapter
  class UnknownAdapter < StandardError; end

  BeginTripResult = Struct.new(:raw_result, keyword_init: true)
  EndTripResult = Struct.new(
    :raw_result,
    :cost_cents,
    :cost_currency,
    :duration_minutes,
    :end_time,
    keyword_init: true,
  )

  class << self
    def register(name, cls)
      @registry ||= {}
      @registry[name.to_s] = cls
    end

    def create(name)
      (cls = @registry[name.to_s]) or
        raise UnknownAdapter, "No registered adapter '#{name}' available: #{@registry.keys.join(', ')}"
      return cls.new
    end
  end

  def begin_trip(trip)
    raise NotImplementedError
  end

  def end_trip(trip)
    raise NotImplementedError
  end
end

require_relative "fake_vendor_adapter"
Suma::Mobility::VendorAdapter.register("fake", Suma::Mobility::FakeVendorAdapter)
