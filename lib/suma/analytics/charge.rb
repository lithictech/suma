# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::Charge < Suma::Analytics::Model(Sequel[:analytics][:charges])
  unique_key :charge_id

  destroy_from Suma::Charge

  denormalize Suma::Charge, with: [
    [:charge_id, :id],
    :opaque_id,
    :created_at,
    :member_id,
    [:order_id, :commerce_order_id],
    [:trip_id, :mobility_trip_id],
    :undiscounted_subtotal,
    :discounted_subtotal,
    :discount_amount,
    [:cash_paid, [:commerce_order, :cash_paid]],
    [:noncash_paid, [:commerce_order, :noncash_paid]],
  ]
end
