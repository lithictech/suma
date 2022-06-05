# frozen_string_literal: true

require "suma/fixtures"
require "suma/payment/book_transaction"

module Suma::Fixtures::BookTransactions
  extend Suma::Fixtures

  fixtured_class Suma::Payment::BookTransaction

  base :book_transaction do
    self.amount_cents ||= Faker::Number.between(from: 100, to: 100_00)
    self.amount_currency ||= "USD"
    self.memo ||= Faker::Lorem.words(number: 3).join(" ")
    self.apply_at ||= Time.now
  end

  before_saving do |instance|
    instance.originating_ledger ||= Suma::Fixtures.ledger.create
    instance.receiving_ledger ||= Suma::Fixtures.ledger.create
    instance
  end

  decorator :from do |led={}|
    led = Suma::Fixtures.ledger(led).create unless led.is_a?(Suma::Payment::Ledger)
    self.originating_ledger = led
  end

  decorator :to do |led|
    led = Suma::Fixtures.ledger(led).create unless led.is_a?(Suma::Payment::Ledger)
    self.receiving_ledger = led
  end
end
