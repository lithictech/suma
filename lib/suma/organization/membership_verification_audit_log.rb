# frozen_string_literal: true

require "suma/organization"
require "suma/postgres/model"

class Suma::Organization::MembershipVerificationAuditLog <
  Suma::Postgres::Model(:organization_membership_verification_audit_logs)
  plugin :state_machine_audit_log

  many_to_one :verification, class: "Suma::Organization::MembershipVerification", key: :verification_id
  many_to_one :actor, class: "Suma::Member"
end
