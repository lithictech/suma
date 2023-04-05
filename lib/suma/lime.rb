# frozen_string_literal: true

require "suma/mobility/gbfs"

require "suma/http"

module Suma::Lime
  include Appydays::Configurable
  include Appydays::Loggable

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
    return Gbfs::HttpClient.new(api_host: self.api_root, auth_token: self.auth_token)
  end

  def self.gbfs_sync_all
    client =  self.gbfs_http_client
    Suma::Mobility::Gbfs::GeofencingZone.new(client:).process
    Suma::Mobility::Gbfs::VehicleStatus.new(client:).sync_all("lime")
  end

  def self.api_headers
    return {
      "Authorization" => "Bearer #{self.auth_token}",
    }
  end

  def self.start_trip(vehicle_id:, user_id:, lat:, lng:, rate_plan_id:, timestamp:)
    response = Suma::Http.post(
      self.api_root + "/trips/start",
      {
        vehicle_id:,
        user_id:,
        location: {
          type: "Feature",
          geometry: {
            type: "Point",
            coordinates: [
              lng,
              lat,
            ],
          },
          properties: {
            timestamp:,
          },
        },
        rate_plan_id:,
      },
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def self.complete_trip = raise NotImplementedError
  def self.get_trip = raise NotImplementedError
  def self.get_vehcile = raise NotImplementedError
  def self.create_user = raise NotImplementedError
end
