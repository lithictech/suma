# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::ProgramPricings
  extend Suma::Fixtures

  fixtured_class Suma::Program::Pricing

  base :program_pricing do
  end

  before_saving do |instance|
    instance.program ||= Suma::Fixtures.program.create
    instance.vendor_service ||= Suma::Fixtures.vendor_service.create
    instance.vendor_service_rate ||= Suma::Fixtures.vendor_service_rate.create
    instance
  end
end
