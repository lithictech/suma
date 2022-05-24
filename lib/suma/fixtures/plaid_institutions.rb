# frozen_string_literal: true

require "suma/fixtures"
require "suma/plaid_institution"

module Suma::Fixtures::PlaidInstitutions
  extend Suma::Fixtures

  fixtured_class Suma::PlaidInstitution

  base :plaid_institution do
    self.name ||= Faker::Bank.name
    self.institution_id ||= Faker::Alphanumeric.alpha(number: 4)
    self.routing_numbers ||= [Faker::Bank.routing_number]
  end
end
