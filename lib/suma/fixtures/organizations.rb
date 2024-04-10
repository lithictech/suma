# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/organization"

module Suma::Fixtures::Organizations
  extend Suma::Fixtures

  fixtured_class Suma::Organization

  base :organization do
    self.name ||= Faker::Company.name
  end

  before_saving do |instance|
    instance
  end
end