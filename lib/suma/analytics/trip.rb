# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::Trip < Suma::Analytics::Model(Sequel[:analytics][:trips])
  unique_key :trip_id

  destroy_from Suma::Mobility::Trip
  denormalize Suma::Mobility::Trip, with: [
    [:trip_id, :id],
    :created_at,

    :member_id,
    :vendor_service_id,
    [:vendor_service_name, [:vendor_service, :internal_name]],
    [:vendor_id, [:vendor_service, :vendor_id]],
    [:vendor_name, [:vendor_service, :vendor, :name]],
    :vendor_service_rate_id,
    [:vendor_service_rate_name, [:vendor_service_rate, :name]],

    :began_at,
    :begin_lat,
    :begin_lng,
    :ended_at,
    :end_lat,
    :end_lng,

    [:undiscounted_cost, [:charge, :undiscounted_cost]],
    [:customer_cost, [:charge, :customer_cost]],
    [:savings, [:charge, :savings]],
    :funded_cost,
    :paid_cost,
    :cash_paid,
    :noncash_paid,
  ]
end
