# frozen_string_literal: true

require "suma/simple_registry"

# TripProviders can begin and end trips with another system,
# usually "mobility-as-a-service" providers of some sort.
module Suma::Mobility::TripProvider
  extend Suma::SimpleRegistry

  # Begin the trip with the underlying vendor.
  # The adapter can set fields on the trip, which will be saved on success.
  #
  # @param trip [Suma::Mobility::Trip]
  # @return [Suma::Mobility::BeginTripResult]
  def begin_trip(trip) = raise NotImplementedError

  # End a trip using the underlying adapter.
  # The trip will have its end fields set from what is provided through +Trip#end_trip+.
  # This method can set fields (including end fields) on the trip,
  # which will be saved on success.
  #
  # @param trip [Suma::Mobility::Trip]
  # @return [Suma::Mobility::EndTripResult]
  def end_trip(trip) = raise NotImplementedError

  require_relative "trip_provider/lime_maas"
  register("lime_maas", Suma::Mobility::TripProvider::LimeMaas)
  require_relative "trip_provider/internal"
  register("internal", Suma::Mobility::TripProvider::Internal)
end
