# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::CommerceProducts
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Product

  base :commerce_product do
    self.name ||= Faker::Food.dish
    self.description ||= Faker::Food.description
    self.vendor ||= Suma::Fixtures.vendor(name: "Nancys Farm").create
    self.our_cost_cents ||= Faker::Number.between(from: 700, to: 1000)
    self.our_cost_currency ||= "USD"
  end
end
