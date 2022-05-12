# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::BookTransaction < Suma::Postgres::Model(:payment_book_transactions)
  plugin :timestamps
  plugin :money_fields, :amount

  many_to_one :originating_ledger, class: "Suma::Payment::Ledger"
  many_to_one :receiving_ledger, class: "Suma::Payment::Ledger"
end
