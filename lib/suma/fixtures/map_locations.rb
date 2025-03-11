# frozen_string_literal: true

require "suma/fixtures"
require "suma/map_location"

module Suma::Fixtures::MapLocations
  extend Suma::Fixtures

  fixtured_class Suma::MapLocation

  base :map_location do
    self.lat ||= Faker::Number.between(from: -90.0, to: 90.0)
    self.lng ||= Faker::Number.between(from: -180.0, to: 180.0)
  end

  decorator :at do |lat, lng|
    self.lat = lat
    self.lng = lng
  end
end
