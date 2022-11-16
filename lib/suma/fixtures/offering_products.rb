# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering_product"

module Suma::Fixtures::OfferingProducts
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::OfferingProduct

  base :offering_product do
    self.customer_price_cents ||= Faker::Number.between(from: 600, to: 800)
    self.customer_price_currency ||= "USD"
    self.undiscounted_price_cents ||= Faker::Number.between(from: 900, to: 1000)
    self.undiscounted_price_currency ||= "USD"
  end

  before_saving do |instance|
    instance.product ||= Suma::Fixtures.product.create
    instance.offering ||= Suma::Fixtures.offering.create
    instance
  end

  decorator :costing do |customer, undiscounted|
    self.customer_price = Suma::SpecHelpers.money(customer)
    self.undiscounted_price = Suma::SpecHelpers.money(undiscounted)
  end

  decorator :closed do
    self.closed_at = 2.days.ago
  end

  decorator :product do |p={}|
    p = Suma::Fixtures.product(p).create unless p.is_a?(Suma::Commerce::Product)
    self.product = p
  end
end
