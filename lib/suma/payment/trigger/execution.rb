# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Payment::Trigger::Execution < Suma::Postgres::Model(:payment_trigger_executions)
  many_to_one :trigger, class: "Suma::Payment::Trigger"
  many_to_one :book_transaction, class: "Suma::Payment::BookTransaction"
end
