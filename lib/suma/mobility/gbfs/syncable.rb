# frozen_string_literal: true

require "suma/simple_registry"

# Registry of types that use GBFS sync.
# Registered items must implement #component_vendor_syncs(Suma::Mobility::Gbfs::ComponentSync)
# It must return an array of Suma::Mobility::Gbfs::VendorSync.
module Suma::Mobility::Gbfs::Syncable
  extend Suma::SimpleRegistry

  module Lime
    require "suma/lime"

    SYNCABLE_TYPES = [Suma::Mobility::Gbfs::GeofencingZone, Suma::Mobility::Gbfs::FreeBikeStatus].freeze

    # @param component [Suma::Mobility::Gbfs::ComponentSync]
    def self.component_vendor_syncs(component)
      return [] unless Suma::Lime.configured?
      return [] unless SYNCABLE_TYPES.include?(component.class)
      vs = Suma::Mobility::Gbfs::VendorSync.new(
        client: Suma::Lime.gbfs_http_client,
        vendor: Suma::Lime.mobility_vendor,
        component:,
      )
      return [vs]
    end
  end
  Suma::Mobility::Gbfs::Syncable.register("lime", Lime)

  class Lyft
    require "suma/lyft"

    SYNCABLE_TYPES = [Suma::Mobility::Gbfs::FreeBikeStatus].freeze

    # @param component [Suma::Mobility::Gbfs::ComponentSync]
    def self.component_vendor_syncs(component)
      result = []
      return result unless SYNCABLE_TYPES.include?(component.class)
      Suma::Lyft.vendors_and_markets_json.each do |vendor_key, markets|
        vendor = Suma::Vendor.find!(slug: vendor_key)
        markets.each do |market|
          Suma::Mobility::Gbfs::VendorSync.new(
            client: Suma::Lyft.gbfs_http_client(market),
            vendor:,
            component:,
          )
        end
      end
      return result
    end
  end
  Suma::Mobility::Gbfs::Syncable.register("lyft", Lyft)
end
