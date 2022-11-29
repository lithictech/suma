# frozen_string_literal: true

# Adds some price helpers.
# Requires :quantity and :offering_product
module Suma::Commerce::PricedItem
  def undiscounted_cost = self.quantity * self.offering_product.undiscounted_price
  def customer_cost = self.quantity * self.offering_product.customer_price
  def savings = self.undiscounted_cost - self.customer_cost
end
