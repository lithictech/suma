# frozen_string_literal: true

require "suma/organization"
require "suma/postgres/model"

class Suma::Organization::Membership::VerificationNote <
  Suma::Postgres::Model(:organization_membership_verification_notes)
  many_to_one :verification, class: "Suma::Organization::Membership::Verification", key: :verification_id
  many_to_one :creator, class: "Suma::Member"
  many_to_one :editor, class: "Suma::Member"
end
