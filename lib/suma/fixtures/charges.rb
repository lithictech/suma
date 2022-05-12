# frozen_string_literal: true

require "suma/fixtures"
require "suma/charge"

module Suma::Fixtures::Charges
  extend Suma::Fixtures

  fixtured_class Suma::Charge

  base :charge do
    self.undiscounted_subtotal_cents ||= Faker::Number.between(from: 100, to: 100_00)
    self.undiscounted_subtotal_currency ||= "USD"
  end

  before_saving do |instance|
    instance.customer ||= Suma::Fixtures.customer.create
    instance
  end
end
