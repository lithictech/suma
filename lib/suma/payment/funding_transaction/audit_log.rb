# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Payment::FundingTransaction::AuditLog < Suma::Postgres::Model(:payment_funding_transaction_audit_logs)
  plugin :state_machine_audit_log

  many_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  many_to_one :actor, class: "Suma::Member"
end

# Table: payment_funding_transaction_audit_logs
# ---------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                     | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  at                     | timestamp with time zone | NOT NULL
#  event                  | text                     | NOT NULL
#  to_state               | text                     | NOT NULL
#  from_state             | text                     | NOT NULL
#  reason                 | text                     | NOT NULL DEFAULT ''::text
#  messages               | jsonb                    | DEFAULT '[]'::jsonb
#  funding_transaction_id | integer                  | NOT NULL
#  actor_id               | integer                  |
# Indexes:
#  payment_funding_transaction_audit_logs_pkey | PRIMARY KEY btree (id)
# Foreign key constraints:
#  payment_funding_transaction_audit_l_funding_transaction_id_fkey | (funding_transaction_id) REFERENCES payment_funding_transactions(id)
#  payment_funding_transaction_audit_logs_actor_id_fkey            | (actor_id) REFERENCES members(id) ON DELETE SET NULL
# ---------------------------------------------------------------------------------------------------------------------------------------
