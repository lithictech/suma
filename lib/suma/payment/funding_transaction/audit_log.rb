# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Payment::FundingTransaction::AuditLog < Suma::Postgres::Model(:payment_funding_transaction_audit_logs)
  plugin :state_machine_audit_log

  many_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  many_to_one :actor, class: "Suma::Customer"
end
