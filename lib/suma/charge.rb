# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Charge < Suma::Postgres::Model(:charges)
  plugin :timestamps
  plugin :money_fields, :discounted_amount, :undiscounted_amount

  many_to_one :customer, class: "Suma::Customer"
end
