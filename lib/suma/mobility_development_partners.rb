# frozen_string_literal: true

require "suma/mobility/gbfs"

require "suma/http"

module Suma::MobilityDevelopmentPartners
  include Appydays::Configurable
  include Appydays::Loggable

  UNCONFIGURED_SCHEME_KEY = "get-from-gts-add-to-env"

  configurable(:mdp) do
    setting :api_root, "https://api.share.car/v2/explore"
    setting :gbfs_root, "https://api.share.car/v2/explore"
    setting :auth_token, UNCONFIGURED_SCHEME_KEY
  end

  def self.configured? = self.auth_token != UNCONFIGURED_SCHEME_KEY

  VENDOR_NAME = "Mobility Development Partners"

  # @return [Suma::Vendor]
  def self.mobility_vendor
    return Suma.cached_get("mdp_mobility_vendor") do
      Suma::Vendor.find_or_create_or_find(name: VENDOR_NAME)
    end
  end

  # @return [Suma::Mobility::Gbfs::HttpClient]
  def self.gbfs_http_client
    return Suma::Mobility::Gbfs::HttpClient.new(api_host: self.gbfs_root, auth_token: self.auth_token)
  end
end
