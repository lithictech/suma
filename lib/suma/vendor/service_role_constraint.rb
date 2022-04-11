# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceRoleConstraint < Suma::Postgres::Model(:vendor_service_role_constraints)
  plugin :timestamps

  many_to_one :service, key: :service_id, class: "Suma::Vendor::Service"
  many_to_one :role, key: :role_id, class: "Suma::Role"
end
