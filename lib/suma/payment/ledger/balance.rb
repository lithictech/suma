# frozen_string_literal: true

require "suma/payment"

# Model for a view-generated balance for a ledger.
# Generally useful for querying purposes,
# since at a model level, ledgers have total_credits/total_debits
# which works correctly with eager loading
# (it's possible we want to replace that with this view in the future).
class Suma::Payment::Ledger::Balance < Suma::Postgres::Model(:payment_ledger_balances)
  plugin :hybrid_search, indexable: false
  plugin :money_fields, :balance

  many_to_one :ledger, class: "Suma::Payment::Ledger", read_only: true

  set_primary_key :ledger_id
  class << self
    def read_only? = true
  end
end

# Table: payment_ledger_balances
# ---------------------------------------------------
# Columns:
#  ledger_id             | integer                  |
#  ledger_name           | text                     |
#  balance_cents         | bigint                   |
#  balance_currency      | text                     |
#  latest_transaction_at | timestamp with time zone |
# ---------------------------------------------------
