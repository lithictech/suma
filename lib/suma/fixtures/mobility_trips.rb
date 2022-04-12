# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/mobility/trip"

module Suma::Fixtures::MobilityTrips
  extend Suma::Fixtures

  fixtured_class Suma::Mobility::Trip

  base :mobility_trip do
    self.begin_lat ||= Faker::Number.between(from: -90.0, to: 90.0)
    self.begin_lng ||= Faker::Number.between(from: -180.0, to: 180.0)
    self.began_at ||= Time.now
    self.vehicle_id ||= SecureRandom.hex(8)
  end

  before_saving do |instance|
    instance.customer ||= Suma::Fixtures.customer.create
    instance.vendor_service ||= Suma::Fixtures.vendor_service.mobility.create
    instance.vendor_service_rate ||= Suma::Fixtures.vendor_service_rate.create
    instance
  end

  decorator :ongoing do
    self.end_lat = nil
    self.end_lng = nil
    self.ended_at = nil
  end

  decorator :ended do
    self.end_lat ||= self.begin_lat + 0.5
    self.end_lng ||= self.begin_lng + 0.5
    self.ended_at ||= Time.now
  end
end
