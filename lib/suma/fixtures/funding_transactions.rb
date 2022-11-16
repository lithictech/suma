# frozen_string_literal: true

require "suma/fixtures"
require "suma/payment/funding_transaction"

module Suma::Fixtures::FundingTransactions
  extend Suma::Fixtures

  fixtured_class Suma::Payment::FundingTransaction

  base :funding_transaction do
    self.amount_cents ||= Faker::Number.between(from: 100, to: 100_00)
    self.amount_currency ||= "USD"
  end

  before_saving do |instance|
    instance.memo ||= Suma::Fixtures.translated_text(en: Faker::Lorem.words(number: 3).join(" ")).create
    instance.platform_ledger ||= Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
    instance.originating_payment_account ||= Suma::Fixtures.payment_account.create
    instance.originated_book_transaction ||= Suma::Fixtures.book_transaction.
      from(instance.platform_ledger).
      to(Suma::Payment.ensure_cash_ledger(instance.originating_payment_account)).
      create
    instance
  end

  decorator :member do |m|
    self.originating_payment_account ||= m.payment_account
  end

  decorator :with_fake_strategy do |strategy={}|
    strategy = Suma::Payment::FakeStrategy.create(**strategy) unless strategy.is_a?(Suma::Payment::FakeStrategy)
    self.fake_strategy = strategy
  end
end
