# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceMatchallConstraint < Suma::Postgres::Model(:vendor_service_matchall_constraints)
  plugin :timestamps

  many_to_one :service, key: :service_id, class: "Suma::Vendor::Service"
end
