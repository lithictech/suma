# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/platform_partner"

module Suma::Fixtures::PlatformPartners
  extend Suma::Fixtures

  fixtured_class Suma::PlatformPartner

  base :platform_partner do
    self.name ||= Faker::Company.name
  end
end
