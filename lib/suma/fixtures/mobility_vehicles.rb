# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/mobility/vehicle"

module Suma::Fixtures::MobilityVehicles
  extend Suma::Fixtures

  fixtured_class Suma::Mobility::Vehicle

  base :mobility_vehicle do
    self.lat ||= Faker::Number.between(from: -90.0, to: 90.0)
    self.lng ||= Faker::Number.between(from: -180.0, to: 180.0)
    self.battery_level ||= Faker::Number.between(from: 10, to: 100)
    self.vehicle_type ||= ["ebike", "escooter"].sample
    self.vehicle_id ||= SecureRandom.hex(8)
  end

  before_saving do |instance|
    instance.vendor_service ||= Suma::Fixtures.vendor_service.mobility.create
    instance
  end

  decorator :loc do |lat, lng|
    self.lat = lat
    self.lng = lng
  end

  decorator :escooter do
    self.vehicle_type = "escooter"
  end

  decorator :ebike do
    self.vehicle_type = "ebike"
  end
end
