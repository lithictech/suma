# frozen_string_literal: true

require "appydays/loggable"

require "suma/lime"

class Suma::Lime::MaasClient
  include Appydays::Loggable

  PRODUCTION_API_ROOT = "https://external-api.lime.bike/api/maas/v1/partner"

  attr_accessor :auth_token, :api_root

  def initialize(auth_token, api_root: PRODUCTION_API_ROOT)
    @auth_token = auth_token
    @api_root = api_root
  end

  def api_headers
    return {
      "Authorization" => "Bearer #{self.auth_token}",
    }
  end

  def start_trip(vehicle_id:, user_id:, lat:, lng:, rate_plan_id:, at:)
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

  def complete_trip(trip_id:, lat:, lng:, at:)
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

  def get_trip(trip_id)
    response = Suma::Http.get(
      self.api_root + "/trips/#{trip_id}", headers: self.api_headers, logger: self.logger,
    )
    return response.parsed_response
  end

  def get_vehicle(qr_code_json:, license_plate:)
    response = Suma::Http.get(
      self.api_root + "/vehicle?qr_code=#{qr_code_json}&license_plate=#{license_plate}",
      headers: self.api_headers,
      logger: self.logger,
    )
    response.parsed_response
  end

  def create_user(phone_number:, email_address:, driver_license_verified:)
    response = Suma::Http.post(
      self.api_root + "/users",
      {phone_number:, email_address:, driver_license_verified:},
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  # @param member [Suma::Member]
  def ensure_member_registered(member)
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
