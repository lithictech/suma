# frozen_string_literal: true

require "suma/mobility/gbfs"

require "suma/http"

module Suma::Lyft
  include Appydays::Configurable
  include Appydays::Loggable

  UNCONFIGURED_AUTH_TOKEN = "get-from-lyft-add-to-env"

  configurable(:lyft) do
    setting :gbfs_root, "https://gbfs.lyft.com/gbfs/2.3/pdx/en"
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN
  end

  def self.configured? = self.auth_token != UNCONFIGURED_AUTH_TOKEN

  VENDOR_NAME = "Lyft"

  # @return [Suma::Vendor]
  def self.mobility_vendor
    return Suma.cached_get("lyft_mobility_vendor") do
      Suma::Vendor.find_or_create_or_find(name: VENDOR_NAME)
    end
  end

  # @return [Suma::Mobility::Gbfs::HttpClient]
  def self.gbfs_http_client
    return Suma::Mobility::Gbfs::HttpClient.new(api_host: self.gbfs_root, auth_token: self.auth_token)
  end
end
