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

  def self.scooter_vendor
    org = Suma::Organization.find_or_create(name: "Lime")
    rate = Suma::Vendor::ServiceRate.find_or_create(name: "Ride for free.") do |r|
      r.localization_key = "mobility_free_of_charge"
      r.surcharge = Money.new(0)
      r.unit_amount = Money.new(0)
    end
    lime_vendor = Suma::Vendor.find_or_create(name: "Lime", organization: org)
    cash_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
    if lime_vendor.services_dataset.mobility.empty?
      svc = lime_vendor.add_service(
        internal_name: "Lime Scooters",
        external_name: "Lime E-Scooters",
        mobility_vendor_adapter_key: "lime",
        constraints: [{"form_factor" => "scooter", "propulsion_type" => "electric"}],
      )
      svc.add_category(Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility", parent: cash_category))
      svc.add_rate(rate)
    end
    return lime_vendor
  end

  def self.gbfs_http_client
    return Suma::Mobility::Gbfs::HttpClient.new(api_host: self.gbfs_root, auth_token: self.auth_token)
  end

  def self.gbfs_sync_free_bike_status
    Suma::Mobility::Gbfs::FreeBikeStatus.new(client: self.gbfs_http_client, vendor: self.scooter_vendor).sync_all
  end

  def self.gbfs_sync_geofencing_zones
    Suma::Mobility::Gbfs::GeofencingZone.new(client: self.gbfs_http_client, vendor: self.scooter_vendor).sync_all
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

  def self.ensure_member_registered(member)
    return member.lime_user_id if member.lime_user_id.present?
    user = Suma::Lime.create_user(
      phone_number: member.phone,
      email_address: "members+#{member.id}@sumamembers.org",
      driver_license_verified: false,
    )
    member.update(lime_user_id: user.dig("data", "id"))
    return member.lime_user_id
  end
end
