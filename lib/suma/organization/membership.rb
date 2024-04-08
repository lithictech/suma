# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Organization::Membership < Suma::Postgres::Model(:organization_memberships)
  plugin :timestamps

  # TODO: Find way to constraint one member membership per organization?
  many_to_one :organization, key: :organization_id, class: "Suma::Organization"
  many_to_one :member, class: "Suma::Member"
end
