# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::Offerings
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Offering

  base :offering do
    self.period ||=
      Faker::Number.between(from: 50, to: 2).days.ago..Faker::Number.between(from: 2, to: 50).days.from_now
    self.description ||= Suma::Fixtures.translated_text.create
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
end
