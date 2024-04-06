# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::OrderItem < Suma::Analytics::Model(Sequel[:analytics][:order_items])
  unique_key :checkout_item_id

  denormalize Suma::Commerce::Order, with: :denormalize_order

  def self.denormalize_order(order)
    checkout = order.checkout
    member = checkout.cart.member
    return order.checkout.items.map do |ci|
      {
        checkout_item_id: ci.id,
        order_id: order.id,
        member_id: member.id,
        funded_amount: order.funded_amount.to_f,
        paid_amount: order.paid_amount.to_f,
      }
    end
  end
end
