# frozen_string_literal: true

require "suma/mobility/gbfs"

module Suma::Lyft
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:lyft) do
    setting :gbfs_root, "https://gbfs.lyft.com/gbfs/2.3"
    setting :gbfs_sync_markets, ["pdx"], convert: ->(s) { s.split(",").map(&:strip) }
  end

  VENDOR_NAME = "Lyft"

  # @return [Suma::Vendor]
  def self.mobility_vendor
    return Suma.cached_get("lyft_mobility_vendor") do
      Suma::Vendor.find_or_create_or_find(name: VENDOR_NAME)
    end
  end

  # @return [Suma::Mobility::Gbfs::HttpClient]
  def self.gbfs_http_client(market, lang: "en")
    api_host = "#{self.gbfs_root}/#{market}/#{lang}"
    return Suma::Mobility::Gbfs::HttpClient.new(api_host:, auth_token: nil)
  end
end
