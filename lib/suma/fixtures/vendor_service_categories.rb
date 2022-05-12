# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/vendor/service_category"

module Suma::Fixtures::VendorServiceCategories
  extend Suma::Fixtures

  fixtured_class Suma::Vendor::ServiceCategory

  base :vendor_service_category do
    self.name ||= "RandCategory-#{SecureRandom.hex(3)}"
  end

  before_saving do |instance|
    existing = Suma::Vendor::ServiceCategory[name: instance.name]
    existing || instance
  end

  decorator :mobility do
    self.name = "Mobility"
  end

  decorator :food do
    self.name = "Food"
  end
end
