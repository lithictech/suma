# frozen_string_literal: true

require "suma/organization"
require "suma/postgres/model"

class Suma::Organization::Membership::VerificationNote <
  Suma::Postgres::Model(:organization_membership_verification_notes)
  plugin :timestamps

  many_to_one :verification, class: "Suma::Organization::Membership::Verification", key: :verification_id
  many_to_one :author, class: "Suma::Member"
end
