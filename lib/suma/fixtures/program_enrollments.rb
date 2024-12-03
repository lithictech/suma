# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::ProgramEnrollments
  extend Suma::Fixtures

  fixtured_class Suma::Program::Enrollment

  base :program_enrollment do
    self.approved_at = Faker::Suma.number(2..100).days.ago
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create if instance.organization_id.nil? && instance.role_id.nil?
    instance.program ||= Suma::Fixtures.program.create
    instance
  end

  decorator :unapproved do
    self.approved_at = nil
  end

  decorator :unenrolled do |at=1.minute.ago|
    self.unenrolled_at = at
  end
end
