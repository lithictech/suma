# frozen_string_literal: true

require "mobility/gbfs_http_client"

require "suma/http"
require "suma/method_utilities"

module Suma::Lime
  include Appydays::Configurable
  extend Suma::MethodUtilities

  UNCONFIGURED_AUTH_TOKEN = "get-from-lime-add-to-env"

  class << self
    def configured? = self.auth_token != UNCONFIGURED_AUTH_TOKEN
  end

  configurable(:lime) do
    setting :api_root, "https://fake-lime-api.com"
    setting :gbfs_root, "https://fake-lime-gbfs.com"
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN
  end

  def self.gbfs_http_client
    return GbfsHttpClient.new(api_host: self.api_root, auth_token: self.auth_token)
  end

  def self.gbfs_sync_all
    client =  self.gbfs_http_client
    Suma::Mobility::GbfsGeofencingZone.new(client:).process
    Suma::Mobility::GbfsVehicleStatus.new(client:).sync_all("lime")
  end
end
