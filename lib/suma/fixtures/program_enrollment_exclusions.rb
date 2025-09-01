# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::ProgramEnrollmentExclusions
  extend Suma::Fixtures

  fixtured_class Suma::Program::EnrollmentExclusion

  base :program_enrollment_exclusion do
  end

  before_saving do |instance|
    instance.program ||= Suma::Fixtures.program.create
    instance.member ||= Suma::Fixtures.member.create if instance.role_id.nil?
    instance
  end
end
