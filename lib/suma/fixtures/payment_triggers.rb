# frozen_string_literal: true

require "suma/fixtures"
require "suma/payment/trigger"

module Suma::Fixtures::PaymentTriggers
  extend Suma::Fixtures

  fixtured_class Suma::Payment::Trigger

  base :payment_trigger do
    self.active_during ||=
      Faker::Number.between(from: 50, to: 2).days.ago..Faker::Number.between(from: 2, to: 50).days.from_now
    self.label ||= Faker::Lorem.sentence
    self.match_multiplier ||= Faker::Number.between(from: 0.25, to: 4)
    self.maximum_cumulative_subsidy_cents ||= Faker::Number.between(from: 100_00, to: 100_000)
    self.receiving_ledger_name ||= Faker::Lorem.words(number: 2).join(" ")
  end

  before_saving do |instance|
    instance.memo ||= Suma::Fixtures.translated_text.create
    instance.originating_ledger ||= Suma::Fixtures.ledger.create
    instance.receiving_ledger_contribution_text ||= Suma::Fixtures.translated_text.create
    instance
  end

  decorator :inactive do
    self.active_during_begin = 4.days.ago
    self.active_during_end = 2.days.ago
  end

  decorator :matching do |n=1|
    self.match_multiplier = n
  end

  decorator :up_to do |m|
    self.maximum_cumulative_subsidy_cents = m.cents
  end

  decorator :no_max do
    self.maximum_cumulative_subsidy_cents = 0
  end

  decorator :with_eligibility_requirements, presave: true do |*attrs|
    attrs.each do |attr|
      Suma::Fixtures.eligibility_requirement.attribute(attr).create(resource: self)
    end
  end

  decorator :from do |ledger|
    self.originating_ledger = ledger
    self.receiving_ledger_name = ledger.name
    self.receiving_ledger_contribution_text = ledger.contribution_text
  end

  decorator :from_platform_category do |cat|
    ledger = Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(cat)
    self.originating_ledger = ledger
    self.receiving_ledger_name = ledger.name
    self.receiving_ledger_contribution_text = ledger.contribution_text
  end

  decorator :with_execution, presave: true do |book_x={}|
    unless book_x.is_a?(Suma::Payment::BookTransaction)
      book_x[:originating_ledger] ||= self.originating_ledger
      book_x = Suma::Fixtures.book_transaction.create(book_x)
    end
    self.add_execution(book_transaction: book_x)
  end

  decorator :memo do |en, es: en|
    self.memo = Suma::Fixtures.translated_text.create(en:, es:)
  end
end
