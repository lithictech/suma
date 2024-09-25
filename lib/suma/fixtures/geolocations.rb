# frozen_string_literal: true

require "faker"
require "geokit"

require "suma/fixtures"

module Suma::Fixtures::Geolocations
  extend Suma::Fixtures

  fixtured_class Geokit::GeoLoc

  base :geolocation do
    # Don't set anything up, as nil'ing some things out doesn't work.
  end

  decorator :from_address do |address|
    self.city = address.city
    self.country_code = address.country.upcase
    self.state_code = address.state
    self.street_address = address.address1
    self.zip = address.zip
    self.precision = "address"
  end

  decorator :mork_and_mindys_house do
    self.lat = 40.021391
    self.lng = -105.274983
    self.country_code = "US"
    self.city = "Boulder"
    self.state_code = "CO"
    self.zip = "80302"
    self.street_address = "1619 Pine Street"
    self.district = "Boulder County"
    self.full_address = "1619 Pine Street, Boulder, CO 80302, USA"

    self.suggested_bounds = Geokit::Bounds.new(
      Geokit::LatLng.new(45.522949, -122.660168),
      Geokit::LatLng.new(45.522949, -122.660168),
    )
  end

  decorator :latlng do |lat, lng|
    self.lat = lat
    self.lng = lng
  end

  decorator :successful do
    self.lat ||= Faker::Address.latitude
    self.lng ||= Faker::Address.longitude
    self.country_code ||= "US"
    self.city ||= Faker::Address.city
    self.state ||= Faker::Address.state_abbr
    self.zip ||= Faker::Address.zip
    self.street_address ||= Faker::Address.street_address
    self.district ||= Faker::Address.city
    self.provider ||= "google"
    self.success ||= true
    self.precision ||= "building"

    self.full_address ||=
      "#{self.street_address}, #{self.city}, #{self.state} #{self.zip}, #{self.country_code}"

    self.suggested_bounds = Geokit::Bounds.new(
      Geokit::LatLng.new(self.lat, self.lng),
      Geokit::LatLng.new(self.lat, self.lng),
    )
  end

  decorator :failed do
    self.lat = nil
    self.lng = nil
    self.country_code = nil
    self.city = nil
    self.state = nil
    self.zip = nil
    self.street_address = nil
    self.district = nil
    self.provider = nil
    self.success = false
    self.precision = "unknown"
    self.full_address = ""
    self.suggested_bounds = nil
  end
end
