# frozen_string_literal: true

require "suma/fixtures"
require "suma/supported_currency"

module Suma::Fixtures::SupportedCurrencies
  extend Suma::Fixtures

  fixtured_class Suma::SupportedCurrency

  base :supported_currency do
    self.symbol ||= "$"
    self.code ||= "USD"
    self.funding_minimum_cents ||= Faker::Number.between(from: 500, to: 2000)
    self.funding_maximum_cents ||= Faker::Number.between(from: 5000, to: 100_00)
    self.funding_step_cents ||= 100
    self.cents_in_dollar ||= 100
    self.payment_method_types ||= ["bank_account"]
    self.ordinal ||= rand
  end
end
