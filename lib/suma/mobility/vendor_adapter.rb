# frozen_string_literal: true

require "suma/simple_registry"

module Suma::Mobility::VendorAdapter
  extend Suma::SimpleRegistry

  class Unsupported < StandardError; end

  BeginTripResult = Struct.new(:_, keyword_init: true)
  EndTripResult = Struct.new(
    :raw_result,
    :cost,
    :undiscounted,
    keyword_init: true,
  )

  class << self
    def create(name)
      return self.registry_create!(name)
    end
  end

  # Begin the trip with the underlying vendor.
  # The adapter can set fields on the trip, which will be saved on success.
  #
  # NOTE: If this adapter is for off-platform rides (through a deeplink adapter),
  # raise +Unsupported+.
  #
  # @param [Suma::Mobility::Trip]
  # @return [BeginTripResult]
  def begin_trip(trip) = raise NotImplementedError

  # End a trip using the underlying adapter.
  # The trip will have its end fields set.
  # This method can set fields (including end fields) on the trip,
  # which will be saved on success.
  #
  # NOTE: If this adapter is for off-platform rides (through a deeplink adapter),
  # raise +Unsupported+.
  #
  # @param [Suma::Mobility::Trip]
  # @return [EndTripResult]
  def end_trip(trip) = raise NotImplementedError

  # Should be true for Deep Link adapters.
  #
  # @param [true,false]
  def uses_deep_linking? = raise NotImplementedError

  # True if suma should send receipts.
  # This should be false where the underlying provider takes care of sending receipts
  # (which usually means the provider is charging the member themselves).
  def send_receipts? = raise NotImplementedError

  # Find the anonymous proxy vendor account for the member
  # that satisfies this adapter (usually this means finding one for the right vendor).
  # It is ok to return nil if the account or vendor does not exist.
  # If this is not relevant, raise +Unsupported+.
  #
  # @return [nil,Suma::AnonProxy::VendorAccount]
  def find_anon_proxy_vendor_account(member) = raise NotImplementedError

  def anon_proxy_vendor_account_requires_attention?(member, now:)
    return false unless self.uses_deep_linking?
    account = self.find_anon_proxy_vendor_account(member)
    return true if account.nil?
    return account.auth_to_vendor.needs_attention?(now:)
  end

  require_relative "vendor_adapter/fake"
  register("fake", Suma::Mobility::VendorAdapter::Fake)
  register("demo_deeplink", Suma::Mobility::VendorAdapter::Fake)
  require_relative "vendor_adapter/biketown_deeplink"
  register("biketown_deeplink", Suma::Mobility::VendorAdapter::BiketownDeeplink)
  require_relative "vendor_adapter/lime_deeplink"
  register("lime_deeplink", Suma::Mobility::VendorAdapter::LimeDeeplink)
  require_relative "vendor_adapter/lime_maas"
  register("lime_maas", Suma::Mobility::VendorAdapter::LimeMaas)
  require_relative "vendor_adapter/lyft_deeplink"
  register("lyft_deeplink", Suma::Mobility::VendorAdapter::LyftDeeplink)
  require_relative "vendor_adapter/internal"
  register("internal", Suma::Mobility::VendorAdapter::Internal)
end
