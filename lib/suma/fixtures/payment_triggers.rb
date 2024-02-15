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
    self.receiving_ledger_name ||= Faker::Lorem.words(number: 2)
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

  decorator :with_constraints, presave: true do |*cons|
    cons.each do |c|
      c = Suma::Fixtures.eligibility_constraint.create(c) unless c.is_a?(Suma::Eligibility::Constraint)
      self.add_eligibility_constraint(c)
    end
  end
end
