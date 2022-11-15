# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::CheckoutItem < Suma::Postgres::Model(:commerce_checkout_items)
  plugin :timestamps

  many_to_one :checkout, class: "Suma::Commerce::Checkout"
  # Keep track of the offering product so prices never change on the checkout.
  many_to_one :offering_product, class: "Suma::Commerce::OfferingProduct"
  # Point to the cart item, rather than copying the quantity.
  many_to_one :cart_item, class: "Suma::Commerce::CartItem"

  def undiscounted_cost = self.quantity * self.offering_product.undiscounted_price
  def customer_cost = self.quantity * self.offering_product.customer_price
  def savings = self.undiscounted_cost - self.customer_cost

  def quantity
    return self.immutable_quantity || self.cart_item.quantity
  end
end
