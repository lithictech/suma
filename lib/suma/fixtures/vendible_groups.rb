# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::VendibleGroups
  extend Suma::Fixtures

  fixtured_class Suma::Vendible::Group

  base :vendible_group do
  end

  before_saving do |instance|
    instance.name ||= Suma::Fixtures.translated_text.create(all: "VndGrp-#{SecureRandom.hex(3)}")
    instance
  end

  decorator :with_offering, presave: true do |o={}|
    o = Suma::Fixtures.offering(o).create unless o.is_a?(Suma::Commerce::Offering)
    self.add_commerce_offering(o)
  end

  decorator :with_vendor_service, presave: true do |o={}|
    o = Suma::Fixtures.vendor_service(o).create unless o.is_a?(Suma::Vendor::Service)
    self.add_vendor_service(o)
  end

  decorator :with_, presave: true do |*objs|
    objs.each { |o| o.add_vendible_group(self) }
  end

  decorator :named do |en, es: nil|
    self.name = Suma::Fixtures.translated_text.create(en:, es: es || "(ES) #{en}")
  end
end
