# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::Products
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Product

  base :product do
  end

  before_saving do |instance|
    instance.name ||= Suma::Fixtures.translated_text(en: Faker::Food.dish).create
    instance.description ||= Suma::Fixtures.translated_text(en: Faker::Food.description).create
    instance.vendor ||= Suma::Fixtures.vendor.create
    instance
  end

  decorator :in_offering, presave: true do |offering|
    Suma::Fixtures.offering_product.create(offering:, product: self)
  end

  decorator :with_categories, presave: true do |*cats|
    cats << {} if cats.empty?
    cats.each do |c|
      c = Suma::Fixtures.vendor_service_category.create(c) unless c.is_a?(Suma::Vendor::ServiceCategory)
      self.add_vendor_service_category(c)
    end
  end

  decorator :category, presave: true do |name|
    raise ArgumentError, "#{name} must be a Symbol (the fixture decorator method)" unless name.is_a?(Symbol)
    self.add_vendor_service_category(Suma::Fixtures.vendor_service_category.send(name).create)
  end

  decorator :limited_quantity, presave: true do |on_hand=nil, pending_fulfillment=nil|
    on_hand ||= Faker::Number.between(from: 0, to: 10)
    pending_fulfillment ||= Faker::Number.between(from: 0, to: 10)
    self.inventory!.update(
      limited_quantity: true,
      quantity_on_hand: on_hand,
      quantity_pending_fulfillment: pending_fulfillment,
    )
  end
end
