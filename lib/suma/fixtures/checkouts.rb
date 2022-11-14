# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/checkout"

module Suma::Fixtures::Checkouts
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Checkout

  base :checkout do
  end

  before_saving do |instance|
    instance.cart ||= Suma::Fixtures.cart.create
    instance.fulfillment_option ||= instance.cart.offering.fulfillment_options.first ||
      Suma::Fixtures.offering_fulfillment_option(offering: instance.cart.offering).create
    instance
  end

  decorator :populate_items, presave: true do
    self.cart.items.each do |item|
      self.add_item({cart_item: item, offering_product: item.offering_product})
    end
  end

  decorator :completed do |t=Time.now|
    self.complete(t)
  end
end
