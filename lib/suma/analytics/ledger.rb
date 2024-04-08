# frozen_string_literal: true

require "suma/analytics/model"

class Suma::Analytics::Ledger < Suma::Analytics::Model(Sequel[:analytics][:ledgers])
  unique_key :ledger_id

  destroy_from Suma::Payment::Ledger

  denormalize Suma::Payment::BookTransaction, with: :denormalize_booking_transaction

  def self.denormalize_booking_transaction(bx)
    return [bx.originating_ledger, bx.receiving_ledger].map do |led|
      {
        ledger_id: led.id,
        payment_account_id: led.account_id,
        member_id: led.account.member_id,
        name: led.name,
        balance: led.balance,
        total_credits: led.received_book_transactions.sum(Money.new(0), &:amount),
        total_debits: led.originated_book_transactions.sum(Money.new(0), &:amount),
      }
    end
  end
end
