# frozen_string_literal: true

require "faker"
require "geokit"

require "suma/fixtures"
require "suma/address"

module Suma::Fixtures::Addresses
  extend Suma::Fixtures

  fixtured_class Suma::Address

  depends_on(:geolocations)

  base :address do
    self.address1          ||= Faker::Address.street_address
    self.address2          ||= Faker::Address.secondary_address if rand(1..10) < 3
    self.city              ||= Faker::Address.city
    self.state_or_province ||= Faker::Address.state_abbr
    self.postal_code       ||= Faker::Address.postcode
    self.country           ||= "US"
  end

  decorator :with_geocoding_data do |opts={}|
    self.geocoder_data = Suma::Fixtures.geolocation(opts).successful.from_address(self).instance
  end
end
