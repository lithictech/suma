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
    instance
  end

  decorator :populate_items, presave: true do
    self.cart.items.each do |item|
      (offering_product = item.offering_product) or raise "CartItem[#{item.id}] product has no offering product"
      self.add_item({cart_item: item, offering_product:})
    end
  end

  decorator :completed, presave: true do |t=Time.now|
    self.complete(t)
    self.fulfillment_option ||= self.cart.offering.fulfillment_options.first ||
      Suma::Fixtures.offering_fulfillment_option(offering: self.cart.offering).create
    self.items.each do |it|
      it.update(cart_item_id: nil, immutable_quantity: it.cart_item.quantity)
    end
  end

  decorator :with_fulfillment_option, presave: true do |o={}|
    unless o.is_a?(Suma::Commerce::OfferingFulfillmentOption)
      o = Suma::Fixtures.offering_fulfillment_option(offering: self.cart.offering).create(o)
    end
    self.fulfillment_option = o
  end

  decorator :with_payment_instrument, presave: true do
    self.payment_instrument ||= Suma::Fixtures.send([:card, :bank_account].sample).member(self.cart.member).create
  end
end
