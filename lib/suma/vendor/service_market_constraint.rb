# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceMarketConstraint < Suma::Postgres::Model(:vendor_service_market_constraints)
  plugin :timestamps

  many_to_one :service, key: :service_id, class: "Suma::Vendor::Service"
  many_to_one :market, key: :market_id, class: "Suma::Market"
end
