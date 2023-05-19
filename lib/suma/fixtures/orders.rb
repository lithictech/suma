# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/order"

module Suma::Fixtures::Orders
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Order

  base :order do
  end

  before_saving do |instance|
    instance.checkout ||= Suma::Fixtures.checkout.create
    instance
  end

  decorator :as_purchased_by do |member|
    cart = Suma::Fixtures.cart(member:).with_any_product.create
    self.checkout = Suma::Fixtures.checkout(cart:).with_payment_instrument.populate_items.completed.create
  end

  decorator :claimable do
    self.fulfillment_status = "fulfilling"
    self.order_status = "open"
  end

  decorator :claimed do
    self.fulfillment_status = "fulfilled"
  end
end
