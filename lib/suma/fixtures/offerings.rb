# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::Offerings
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Offering

  base :offering do
    self.period ||= Faker::Suma.number(50..2).days.ago..Faker::Suma.number(2..50).days.from_now
  end

  before_saving do |instance|
    instance.description ||= Suma::Fixtures.translated_text.create
    instance.fulfillment_prompt ||= Suma::Fixtures.translated_text.create
    instance.fulfillment_confirmation ||= Suma::Fixtures.translated_text.create
    instance.fulfillment_instructions ||= Suma::Fixtures.translated_text.create
    instance
  end

  decorator :description do |en, es: nil|
    self.description = Suma::Fixtures.translated_text.create(en:, es: es || "(ES) #{en}")
  end

  decorator :closed do
    self.period_begin = 4.days.ago
    self.period_end = 2.days.ago
  end

  decorator :with_fulfillment, presave: true do |o={}|
    o = Suma::Fixtures.offering_fulfillment_option(o).create(offering: self) unless
      o.is_a?(Suma::Commerce::OfferingFulfillmentOption)
    self.add_fulfillment_option(o)
  end

  decorator :timed_fulfillment do |t=nil|
    t ||= Time.now + Faker::Number.between(from: -50, to: 50).hours
    self.begin_fulfillment_at = t
  end

  decorator :with_constraints, presave: true do |*constraints|
    constraints.each { |c| self.add_eligibility_constraint(c) }
  end
end
