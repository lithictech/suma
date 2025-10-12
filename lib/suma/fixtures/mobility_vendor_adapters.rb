# frozen_string_literal: true

require "suma/fixtures"
require "suma/mobility/vendor_adapter"

module Suma::Fixtures::MobilityVendorAdapters
  extend Suma::Fixtures

  fixtured_class Suma::Mobility::VendorAdapter

  base :mobility_vendor_adapter do
    self.uses_deep_linking = true if self.uses_deep_linking.nil?
  end

  before_saving do |instance|
    instance.vendor_service ||= Suma::Fixtures.vendor_service.create
    instance
  end

  decorator :deeplink do
    self.uses_deep_linking = true
    self.trip_provider_key = ""
  end

  decorator :maas do |key="internal"|
    self.uses_deep_linking = false
    self.trip_provider_key = key
  end
end
