# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::ProgramEnrollments
  extend Suma::Fixtures

  fixtured_class Suma::Program::Enrollment

  base :program_enrollment do
    self.approved_at = Faker::Suma.number(2..100).days.ago
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance.program ||= Suma::Fixtures.program.create
    instance
  end

  decorator :unapproved do
    self.approved_at = nil
  end

  decorator :unenrolled do |at=Time.now|
    self.unenrolled_at = at
  end

  decorator :expired do
    self.period_end = 1.second.ago
  end

  decorator :future do
    self.period_begin = 1.day.from_now
  end
end
