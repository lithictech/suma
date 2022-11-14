# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::CheckoutItem < Suma::Postgres::Model(:commerce_checkout_items)
  plugin :timestamps

  many_to_one :checkout, class: "Suma::Commerce::Checkout"
  many_to_one :offering_product, class: "Suma::Commerce::OfferingProduct"

  def undiscounted_cost = self.quantity * self.offering_product.undiscounted_price
  def customer_cost = self.quantity * self.offering_product.customer_price
  def savings = self.undiscounted_cost - self.customer_cost
end
