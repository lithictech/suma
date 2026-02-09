# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityRequirements
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Requirement

  base :eligibility_requirement do
  end

  before_saving do |instance|
    instance.resource ||= Suma::Fixtures.send([:program, :payment_trigger].sample).create
    instance
  end
end
