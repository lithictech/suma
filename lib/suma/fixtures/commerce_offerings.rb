# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::CommerceOfferings
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Offering

  base :commerce_offering do
    self.period ||=  Sequel::Postgres::PGRange.new(2.days.ago, 2.days.from_now)
    self.description ||= Faker::Food.description
  end

  decorator :period do |begin_time, end_time|
    self.period = Sequel::Postgres::PGRange.new(begin_time, end_time)
  end

  decorator :closed do
    self.period_begin = 4.days.ago
    self.period_end = 2.days.ago
  end
end
