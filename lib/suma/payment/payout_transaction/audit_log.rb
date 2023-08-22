# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Payment::PayoutTransaction::AuditLog < Suma::Postgres::Model(:payment_payout_transaction_audit_logs)
  plugin :state_machine_audit_log

  many_to_one :payout_transaction, class: "Suma::Payment::PayoutTransaction"
  many_to_one :actor, class: "Suma::Member"
end
