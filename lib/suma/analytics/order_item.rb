# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::OrderItem < Suma::Analytics::Model(Sequel[:analytics][:order_items])
  unique_key :checkout_item_id

  destroy_from Suma::Commerce::CheckoutItem

  denormalize Suma::Commerce::Order, with: :denormalize_order

  def self.denormalize_order(order)
    checkout = order.checkout
    member = checkout.cart.member
    return order.checkout.items.map do |ci|
      {
        checkout_item_id: ci.id,
        created_at: order.created_at,
        order_id: order.id,
        member_id: member.id,
        undiscounted_cost: ci.undiscounted_cost,
        customer_cost: ci.customer_cost,
        savings: ci.savings,
      }
    end
  end
end
