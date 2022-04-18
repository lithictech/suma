# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/vendor/service_rate"

module Suma::Fixtures::VendorServiceRates
  extend Suma::Fixtures

  fixtured_class Suma::Vendor::ServiceRate

  base :vendor_service_rate do
    self.unit_amount_cents.nil? && (self.unit_amount = 0)
    self.surcharge_cents.nil? && (self.surcharge = 0)
  end

  decorator :unit_amount do |cents|
    self.unit_amount_cents = cents || Faker::Number.between(from: 10, to: 500)
  end

  decorator :surcharge do |cents|
    self.surcharge_cents = cents || Faker::Number.between(from: 10, to: 500)
  end

  decorator :discounted_by do |percent|
    # (origamt / discamt) = mult
    # (100 / 90) = 1.1111
    # 90 * 1.1111 = 100
    # 100 * 0.9 = 90
    # 90 / 0.9 = 100
    mult = 1 - percent
    self.undiscounted_rate = Suma::Fixtures.
      vendor_service_rate(
        unit_amount: self.unit_amount / mult,
        surcharge: self.surcharge / mult,
      ).create
  end

  decorator :for_service, presave: true do |vs={}|
    vs = Suma::Fixtures.vendor_service(vs).create unless vs.is_a?(Suma::Vendor::Service)
    self.add_service(vs)
  end
end
