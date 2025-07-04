# frozen_string_literal: true

require "suma/fixtures"
require "suma/role"

module Suma::Fixtures::Roles
  extend Suma::Fixtures

  fixtured_class Suma::Role

  base :role do
    self.name ||= "#{Faker::Name.name}-#{SecureRandom.hex(2)}"
  end
end
