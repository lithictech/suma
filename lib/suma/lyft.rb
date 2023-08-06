# frozen_string_literal: true

require "suma/mobility/gbfs"

module Suma::Lyft
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:lyft) do
    setting :gbfs_root, "https://gbfs.lyft.com/gbfs/2.3"
    # Key is the vendor name (can be 'lyft' when Lyft is self-operating).
    # Value is the market name, used in the GBFS feed.
    # For example: {'biketown' => ['pdx']}
    setting :vendors_and_markets_json, {}, convert: ->(s) { JSON.parse(s) }
  end

  # @return [Suma::Mobility::Gbfs::HttpClient]
  def self.gbfs_http_client(market, lang: "en")
    api_host = "#{self.gbfs_root}/#{market}/#{lang}"
    return Suma::Mobility::Gbfs::HttpClient.new(api_host:, auth_token: nil)
  end
end
