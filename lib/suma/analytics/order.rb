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
    [:member_id, [:checkout, :cart, :member_id]],
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
    [:offering_id, [:checkout, :cart, :offering_id]],
    [:offering_name, [:checkout, :cart, :offering, :description, :en]],
    [:offering_begin, [:checkout, :cart, :offering, :period, :begin]],
    [:offering_end, [:checkout, :cart, :offering, :period, :end]],
  ]
end

# Table: analytics.orders
# ---------------------------------------------------------------------------------------------
# Columns:
#  pk                 | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  order_id           | integer                  | NOT NULL
#  created_at         | timestamp with time zone |
#  order_status       | text                     |
#  fulfillment_status | text                     |
#  member_id          | integer                  |
#  undiscounted_cost  | numeric                  |
#  customer_cost      | numeric                  |
#  savings            | numeric                  |
#  handling           | numeric                  |
#  taxable_cost       | numeric                  |
#  tax                | numeric                  |
#  total              | numeric                  |
#  funded_cost        | numeric                  |
#  paid_cost          | numeric                  |
#  cash_paid          | numeric                  |
#  noncash_paid       | numeric                  |
#  offering_id        | integer                  |
#  offering_name      | text                     |
#  offering_begin     | timestamp with time zone |
#  offering_end       | timestamp with time zone |
# Indexes:
#  orders_pkey         | PRIMARY KEY btree (pk)
#  orders_order_id_key | UNIQUE btree (order_id)
# ---------------------------------------------------------------------------------------------
