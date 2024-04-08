# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::Order < Suma::Analytics::Model(Sequel[:analytics][:orders])
  unique_key :order_id

  destroy_from Suma::Commerce::Order
  denormalize Suma::Commerce::Order, with: [
    [:order_id, :id],
    :created_at,
    :order_status,
    :fulfillment_status,
    [:member_id, ->(o) { o.checkout.cart.member_id }],
    :undiscounted_cost,
    :customer_cost,
    :savings,
    :handling,
    :taxable_cost,
    :tax,
    :total,
    :funded_cost,
    :paid_cost,
    :cash_paid,
    :noncash_paid,
  ]
end
