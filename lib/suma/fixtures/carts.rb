# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/cart"

module Suma::Fixtures::Carts
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Cart

  base :cart do
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance.offering ||= Suma::Fixtures.offering.create
    instance
  end

  decorator :with_product, presave: true do |product, quantity=1, **opts|
    self.add_item(product:, quantity:, timestamp: 0, **opts)
  end

  decorator :with_offering_of_product, presave: true do |product, quantity=1, **opts|
    Suma::Fixtures.offering_product(product:, offering: self.offering).create
    self.add_item(product:, quantity:, timestamp: 0, **opts)
  end

  decorator :with_any_product, presave: true do |quantity: 1|
    product = Suma::Fixtures.product.with_categories.create
    Suma::Fixtures.offering_product(product:, offering: self.offering).create
    self.add_item(product:, quantity:, timestamp: 0)
  end
end
