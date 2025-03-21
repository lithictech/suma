# frozen_string_literal: true

require "suma/mobility/gbfs"

require "suma/http"

module Suma::Lime
  include Appydays::Configurable
  include Appydays::Loggable

  UNCONFIGURED_AUTH_TOKEN = "get-from-lime-add-to-env"

  configurable(:lime) do
    setting :api_root, "https://external-api.lime.bike/api/maas/v1/partner"
    setting :gbfs_root, "https://data.lime.bike/api/partners/v2/gbfs_transit"
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN
  end

  def self.configured? = self.auth_token != UNCONFIGURED_AUTH_TOKEN

  VENDOR_NAME = "Lime"

  # @return [Suma::Vendor]
  def self.mobility_vendor
    return Suma.cached_get("lime_mobility_vendor") do
      Suma::Vendor.find_or_create_or_find(name: VENDOR_NAME)
    end
  end

  class LimeGbfsHttpClient < Suma::Mobility::Gbfs::HttpClient
    # Lime 404's on these. Maybe we should be looking at the gbfs meta/index file to see what's supported.
    # Can add in the future.
    def fetch_station_status = nil
    def fetch_station_information = nil
  end

  # @return [Suma::Mobility::Gbfs::HttpClient]
  def self.gbfs_http_client
    return LimeGbfsHttpClient.new(api_host: self.gbfs_root, auth_token: self.auth_token)
  end

  def self.api_headers
    return {
      "Authorization" => "Bearer #{self.auth_token}",
    }
  end

  def self.start_trip(vehicle_id:, user_id:, lat:, lng:, rate_plan_id:, at:)
    response = Suma::Http.post(
      self.api_root + "/trips/start",
      {
        vehicle_id:,
        user_id:,
        location: {
          type: "Feature",
          # TODO: Add a test that passes in lat/lng as Decimal (BigDecimal?) and make sure it casts to float.
          geometry: {type: "Point", coordinates: [lng.to_f, lat.to_f]},
          properties: {timestamp: (at.to_f * 1000).to_i},
        },
        rate_plan_id:,
      },
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def self.complete_trip(trip_id:, lat:, lng:, at:)
    response = Suma::Http.post(
      self.api_root + "/trips/#{trip_id}/complete",
      {
        location: {
          type: "Feature",
          geometry: {type: "Point", coordinates: [lng.to_f, lat.to_f]},
          properties: {timestamp: (at.to_f * 1000).to_i},
        },
      },
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  def self.get_trip(trip_id)
    response = Suma::Http.get(
      self.api_root + "/trips/#{trip_id}", headers: self.api_headers, logger: self.logger,
    )
    return response.parsed_response
  end

  def self.get_vehicle(qr_code_json:, license_plate:)
    response = Suma::Http.get(
      self.api_root + "/vehicle?qr_code=#{qr_code_json}&license_plate=#{license_plate}",
      headers: self.api_headers,
      logger: self.logger,
    )
    response.parsed_response
  end

  def self.create_user(phone_number:, email_address:, driver_license_verified:)
    response = Suma::Http.post(
      self.api_root + "/users",
      {phone_number:, email_address:, driver_license_verified:},
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  # @param member [Suma::Member]
  def self.ensure_member_registered(member)
    return member.lime_user_id if member.lime_user_id.present?
    user = self.create_user(
      phone_number: member.phone,
      email_address: "members+#{member.id}@sumamembers.org",
      driver_license_verified: false,
    )
    member.update(lime_user_id: user.dig("data", "id"))
    return member.lime_user_id
  end
end
