# frozen_string_literal: true

require "appydays/loggable"

require "suma/mobility/gbfs/client"

class Suma::Mobility::Gbfs::HttpClient < Suma::Mobility::Gbfs::Client
  include Appydays::Loggable

  attr_reader :api_host, :auth_token

  def initialize(api_host:, auth_token:)
    super()
    @api_host = api_host
    @auth_token = auth_token
  end

  def headers
    h = {}
    h["Authorization"] = "Bearer #{self.auth_token}" if self.auth_token
    return h
  end

  def fetch_json(part)
    begin
      response = Suma::Http.get(
        "#{self.api_host}/#{part}.json",
        headers: self.headers,
        logger: self.logger,
      )
    rescue Suma::Http::Error => e
      # 404's usually mean the item isn't supported (i.e., status_information for a dockless feed).
      # This could be made faster in the future and checked in the gbfs.json file first, but for now let's just 404.
      return nil if e.status == 404
      raise e
    end
    return response.parsed_response
  end

  def fetch_geofencing_zones = self.fetch_json("geofencing_zones")
  def fetch_free_bike_status = self.fetch_json("free_bike_status")
  def fetch_vehicle_types = self.fetch_json("vehicle_types")
  def fetch_station_status = self.fetch_json("station_status")
  def fetch_station_information = self.fetch_json("station_information")
end
