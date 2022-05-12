# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Charge < Suma::Postgres::Model(:charges)
  plugin :timestamps
  plugin :money_fields, :undiscounted_subtotal

  many_to_one :customer, class: "Suma::Customer"
  many_to_one :mobility_trip, class: "Suma::Mobility::Trip"
  many_to_many :book_transactions,
               class: "Suma::Payment::BookTransaction",
               join_table: :charges_payment_book_transactions,
               left_key: :charge_id,
               right_key: :book_transaction_id

  def discounted_subtotal
    return self.book_transactions.sum(Money.new(0), &:amount)
  end
end
