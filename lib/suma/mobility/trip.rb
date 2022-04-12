# frozen_string_literal: true

require "suma/mobility"
require "suma/postgres/model"

class Suma::Mobility::Trip < Suma::Postgres::Model(:mobility_trips)
  class OngoingTrip < StandardError; end

  plugin :timestamps

  many_to_one :vendor_service, key: :vendor_service_id, class: "Suma::Vendor::Service"
  many_to_one :vendor_service_rate, key: :vendor_service_rate_id, class: "Suma::Vendor::ServiceRate"
  many_to_one :customer, key: :customer_id, class: "Suma::Customer"

  def self.start_trip(customer:, vehicle_id:, vendor_service:, rate:, lat:, lng:, at: Time.now)
    self.db.transaction(savepoint: true) do
      return self.create(
        customer:,
        vehicle_id:,
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: lat,
        begin_lng: lng,
        began_at: at,
      )
    end
  rescue Sequel::UniqueConstraintViolation => e
    raise OngoingTrip, "customer #{customer.id} is already in a trip" if
      e.to_s.include?("one_active_ride_per_customer")
    raise
  end

  def end_trip(lat:, lng:, at: Time.now)
    self.update(
      end_lat: lat,
      end_lng: lng,
      ended_at: at,
    )
  end
end
