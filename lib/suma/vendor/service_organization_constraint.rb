# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceOrganizationConstraint < Suma::Postgres::Model(:vendor_service_organization_constraints)
  plugin :timestamps

  many_to_one :service, key: :service_id, class: "Suma::Vendor::Service"
  many_to_one :organization, key: :organization_id, class: "Suma::Organization"
end
