# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Charge < Suma::Postgres::Model(:charges)
  plugin :timestamps
  plugin :money_fields, :discounted_subtotal, :undiscounted_subtotal

  many_to_one :customer, class: "Suma::Customer"
  many_to_one :mobility_trip, class: "Suma::Mobility::Trip"
end
