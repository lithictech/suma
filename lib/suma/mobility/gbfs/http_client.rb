# frozen_string_literal: true

require "appydays/loggable"
class Suma::Mobility::Gbfs::HttpClient
  include Appydays::Loggable

  attr_reader :api_host, :auth_token

  def initialize(api_host:, auth_token:)
    @api_host = api_host
    @auth_token = auth_token
  end

  def headers
    return {
      "Authorization" => "Bearer #{self.auth_token}",
    }
  end

  def fetch_geofencing_zones
    response = Suma::Http.get(
      self.api_host.to_s + "/geofencing_zones.json",
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def fetch_free_bike_status
    response = Suma::Http.get(
      self.api_host.to_s + "/free_bike_status.json",
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def fetch_vehicle_types
    response = Suma::Http.get(
      self.api_host.to_s + "/vehicle_types.json",
      headers: self.headers,
      logger: self.logger,
    )
    return response.parsed_response
  end
end
