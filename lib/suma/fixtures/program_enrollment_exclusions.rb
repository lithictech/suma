# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::ProgramEnrollmentExclusions
  extend Suma::Fixtures

  fixtured_class Suma::Program::EnrollmentExclusion

  base :program_enrollment_exclusion do
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance.program ||= Suma::Fixtures.program.create
    instance
  end
end
