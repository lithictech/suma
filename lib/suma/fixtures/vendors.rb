# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/vendor"

module Suma::Fixtures::Vendors
  extend Suma::Fixtures

  fixtured_class Suma::Vendor

  base :vendor do
    self.name ||= Faker::Company.name
  end

  before_saving do |instance|
    instance
  end
end
