# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/market"

module Suma::Fixtures::Markets
  extend Suma::Fixtures

  fixtured_class Suma::Market

  base :market do
    self.name ||= Faker::Address.city
  end
end
