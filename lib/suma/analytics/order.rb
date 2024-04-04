# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::Order < Suma::Analytics::Model(Sequel[:analytics][:orders])
  unique_key :order_id

  denormalize Suma::Commerce::Order, with: :denormalize_order

  def self.denormalize_order(order)
    member = order.checkout.cart.member
    return {
      order_id: order.id,
      member_id: member.id,
      funded_amount: order.funded_amount.to_f,
      paid_amount: order.paid_amount.to_f,
    }
  end
end
