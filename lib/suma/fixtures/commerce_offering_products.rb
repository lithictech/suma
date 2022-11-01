# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering_product"

module Suma::Fixtures::CommerceOfferingProducts
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::OfferingProduct

  base :commerce_offering_product do
    t1 = Time.parse("2011-01-01T00:00:00Z")
    t2 = Time.parse("2012-02-01T00:00:00Z")
    self.product ||= Suma::Fixtures.commerce_product.create
    self.offering ||= Suma::Fixtures.commerce_offering.create(period: Sequel::Postgres::PGRange.new(t1, t2))
    self.customer_price_cents ||= Faker::Number.between(from: 600, to: 800)
    self.customer_price_currency ||= "USD"
    self.undiscounted_price_cents ||= Faker::Number.between(from: 900, to: 1000)
    self.undiscounted_price_currency ||= "USD"
    self.closed_at ||= nil
  end

  decorator :closed do
    self.closed_at = 2.days.ago
  end
end
