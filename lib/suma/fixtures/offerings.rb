# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::Offerings
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Offering

  base :offering do
    self.period ||=
      Faker::Number.between(from: 50, to: 2).days.ago..Faker::Number.between(from: 2, to: 50).days.from_now
  end

  before_saving do |instance|
    instance.description ||= Suma::Fixtures.translated_text.create
    instance.fulfillment_prompt ||= Suma::Fixtures.translated_text.create
    instance.fulfillment_confirmation ||= Suma::Fixtures.translated_text.create
    instance
  end

  decorator :description do |en, es: nil|
    self.description = Suma::Fixtures.translated_text.create(en:, es: es || "(ES) #{en}")
  end

  decorator :period do |begin_time, end_time|
    self.period = Sequel::Postgres::PGRange.new(begin_time, end_time)
  end

  decorator :closed do
    self.period_begin = 4.days.ago
    self.period_end = 2.days.ago
  end

  decorator :with_fulfillment, presave: true do |options|
    Suma::Fixtures.offering_fulfillment_option(options).create(offering: self) unless
      options.is_a?(Suma::Commerce::OfferingFulfillmentOption)
  end

  decorator :timed_fulfillment do |t=nil|
    t ||= Time.now + Faker::Number.between(from: -50, to: 50).hours
    self.begin_fulfillment_at = t
  end

  decorator :with_constraints, presave: true do |*constraints|
    constraints.each { |c| self.add_eligibility_constraint(c) }
  end
end
