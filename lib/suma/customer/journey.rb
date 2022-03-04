# frozen_string_literal: true

require "suma/postgres"
require "suma/customer"

class Suma::Customer::Journey < Suma::Postgres::Model(:customer_journeys)
  plugin :timestamps

  many_to_one :customer, class: Suma::Customer
end
