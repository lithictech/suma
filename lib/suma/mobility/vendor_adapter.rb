# frozen_string_literal: true

require "suma/simple_registry"

module Suma::Mobility::VendorAdapter
  extend Suma::SimpleRegistry

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
    def create(name)
      return self.registry_create!(name)
    end
  end

  def begin_trip(trip)
    raise NotImplementedError
  end

  def end_trip(trip)
    raise NotImplementedError
  end

  require_relative "fake_vendor_adapter"
  register("fake", Suma::Mobility::FakeVendorAdapter)
end
