# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering"

module Suma::Fixtures::CommerceOfferings
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Offering

  base :commerce_offering do
    t1 = Time.parse("2011-01-01T00:00:00Z")
    t2 = Time.parse("2012-02-01T00:00:00Z")
    self.period ||=  Sequel::Postgres::PGRange.new(t1, t2)
    self.description ||= Faker::Food.description
  end

  decorator :period do |begin_time, end_time|
    self.period = Sequel::Postgres::PGRange.new(begin_time, end_time)
  end
end
