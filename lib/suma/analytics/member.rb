# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::Member < Suma::Analytics::Model(Sequel[:analytics][:members])
  unique_key :member_id

  destroy_from Suma::Member
  denormalize Suma::Member, with: :denormalize_member
  denormalize Suma::Commerce::Order, with: :denormalize_order

  def self.denormalize_member(member)
    return {member_id: member.id, phone: member.phone}
  end

  def self.denormalize_order(order)
    member = order.checkout.cart.member
    return {member_id: member.id, order_count: member.orders_dataset.count}
  end
end
