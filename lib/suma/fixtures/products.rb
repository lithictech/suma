# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::Products
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Product

  base :product do
    self.our_cost_cents ||= Faker::Number.between(from: 700, to: 1000)
    self.our_cost_currency ||= "USD"
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
end
