# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization::MembershipVerification < Suma::Postgres::Model(:organization_membership_verifications)
  include Suma::AdminLinked

  plugin :state_machine
  plugin :timestamps

  one_to_many :audit_logs,
              class: "Suma::Organization::MembershipVerificationAuditLog",
              order: Sequel.desc(:at),
              key: :verification_id
  many_to_one :membership, class: "Suma::Organization"

  state_machine :status, initial: :created do
    state :created,
          :in_progress,
          :verified,
          :ineligible,
          :abandoned

    event :start do
      transition created: :in_progress
    end
    event :abandon do
      transition in_progress: :abandoned
    end
    event :resume do
      transition abandoned: :in_progress
    end
    event :reject do
      transition in_progress: :ineligible
    end
    event :approve do
      transition in_progress: :verified
    end

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  def rel_admin_link = "/membership-verification/#{self.id}"
end
