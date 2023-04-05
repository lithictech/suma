# frozen_string_literal: true

require "mobility/gbfs_http_client"

require "suma/http"
require "suma/method_utilities"

module Suma::Lime
  include Appydays::Configurable
  extend Suma::MethodUtilities

  UNCONFIGURED_AUTH_TOKEN = "get-from-front-add-to-env"

  class << self
    def configured? = self.auth_token != UNCONFIGURED_AUTH_TOKEN
  end

  configurable(:lime) do
    setting :api_host, "https://data.lime.bike/api/partners/v2/gbfs_transit"
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN
  end

  def self.gbfs_sync_all
    client = GbfsHttpClient.new(api_host: self.api_host,
                                auth_token: self.auth_token,)
    Suma::Mobility::GbfsGeofencingZone.new(client:).process
    Suma::Mobility::GbfsVehicleStatus.new(client:).sync_all("lime")
  end
end
