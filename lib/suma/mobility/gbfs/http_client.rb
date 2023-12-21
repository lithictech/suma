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

  def one_day_from_now = 1.day.from_now.strftime("%F") + " 00:00:00"
  def two_days_from_now = 2.days.from_now.strftime("%F") + " 00:00:00"

  def fetch_mdp_stations_available(vehicle_types:)
    response = Suma::Http.post(
      self.api_host.to_s + "/stations",
      {
        schemeKey: self.auth_token,
        pickUpDatetime: self.one_day_from_now,
        dropOffDatetime: self.two_days_from_now,
        vehicleTypes: vehicle_types,
      },
      headers: {},
      logger: self.logger,
    )
    return response.parsed_response
  end

  def fetch_mdp_station_models_available(station:, vehicle_types:)
    response = Suma::Http.post(
      self.api_host.to_s + "/models/available",
      {
        schemeKey: self.auth_token,
        pickUpDatetime: self.one_day_from_now,
        dropOffDatetime: self.two_days_from_now,
        vehicleTypes: vehicle_types,
        station:,
      },
      headers: {},
      logger: self.logger,
    )
    return response.parsed_response
  end

  def fetch_mdp_vehicle_types
    response = Suma::Http.post(
      self.api_host.to_s + "/vehicle-types", {schemeKey: self.auth_token}, headers: {}, logger: self.logger,
    )
    return response.parsed_response
  end
end
