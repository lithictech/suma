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

  # Begin the trip with the underlying vendor.
  # Used for MaaS and Proxy adapters. See /docs/mobility.md.
  # @param [Suma::Mobility::Trip]
  def begin_trip(trip) = raise NotImplementedError
  # End a trip. See #begin_trip.
  # @param [Suma::Mobility::Trip]
  def end_trip(trip) = raise NotImplementedError

  # Should be true for Deep Link adapters. See /docs/mobility.md.
  # @param [true,false]
  def uses_deep_linking? = raise NotImplementedError
  # Find the anonymous proxy vendor account for the member
  # that satisfies this adapter (usually this means finding one for the right vendor).
  # It is ok to return nil if the account or vendor does not exist.
  # @return [nil,Suma::AnonProxy::VendorAccount]
  def find_anon_proxy_vendor_account(member, vendor) = raise NotImplementedError

  def anon_proxy_vendor_account_requires_attention?(member, vendor)
    return false unless self.uses_deep_linking?
    account = self.find_anon_proxy_vendor_account(member, vendor)
    return true if account.nil?
    return account.address_required?
  end

  require_relative "vendor_adapter/fake"
  register("fake", Suma::Mobility::VendorAdapter::Fake)
  require_relative "vendor_adapter/lime_maas"
  register("lime_maas", Suma::Mobility::VendorAdapter::LimeMaas)
  require_relative "vendor_adapter/native_app_deeplink"
  register("native_app_deeplink", Suma::Mobility::VendorAdapter::NativeAppDeeplink)
end
