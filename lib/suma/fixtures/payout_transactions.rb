# frozen_string_literal: true

require "suma/fixtures"
require "suma/payment/payout_transaction"

module Suma::Fixtures::PayoutTransactions
  extend Suma::Fixtures

  fixtured_class Suma::Payment::PayoutTransaction

  class << self
    def ensure_fixturable(factory) = super.with_fake_strategy
  end

  base :payout_transaction do
    self.amount_cents ||= Faker::Number.between(from: 100, to: 100_00)
    self.amount_currency ||= "USD"
  end

  before_saving do |instance|
    instance.memo ||= Suma::Fixtures.translated_text(en: Faker::Lorem.words(number: 3).join(" ")).create
    instance.platform_ledger ||= Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
    instance.originating_payment_account ||= Suma::Fixtures.payment_account.create
    instance
  end

  decorator :member do |m|
    self.originating_payment_account ||= m.payment_account
  end

  decorator :with_fake_strategy do |strategy={}|
    strategy = Suma::Payment::FakeStrategy.create(**strategy) unless strategy.is_a?(Suma::Payment::FakeStrategy)
    self.fake_strategy = strategy
  end

  def self.refund_of(fx, originating_instrument, apply_credit: :infer, amount: fx.amount, apply_at: Time.now)
    fx.strategy.set_response(:originating_instrument, originating_instrument)
    strategy = Suma::Payment::FakeStrategy.new
    strategy.set_response(:check_validity, [])
    strategy.set_response(:ready_to_send_funds?, false)
    px = Suma::Payment::PayoutTransaction.initiate_refund(
      fx,
      amount:,
      apply_at:,
      strategy:,
      apply_credit:,
    )
    fx.associations.delete(:refund_payout_transactions)
    return px
  end
end
