# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.create }
  let(:now) { Time.now }

  it "can represent a blank/empty member" do
    d = described_class.new(member, at: now)
    expect(d).to have_attributes(cash_balance: money("$0"), program_enrollments: [])
  end

  it "includes enrolled programs" do
    pe1 = Suma::Fixtures.program_enrollment.create(member:)
    pe2 = Suma::Fixtures.program_enrollment.create(member:)
    expect(described_class.new(member, at: now)).to have_attributes(
      program_enrollments: have_same_ids_as(pe1, pe2),
    )
  end

  it "sorts enrollments by program ordinal" do
    p3 = Suma::Fixtures.program.create(ordinal: 3)
    p1 = Suma::Fixtures.program.create(ordinal: 1)
    p2 = Suma::Fixtures.program.create(ordinal: 2)
    pe3 = Suma::Fixtures.program_enrollment.create(member:, program: p3)
    pe1 = Suma::Fixtures.program_enrollment.create(member:, program: p1)
    pe2 = Suma::Fixtures.program_enrollment.create(member:, program: p2)
    enrollments = described_class.new(member, at: now).program_enrollments
    expect(enrollments.first).to have_attributes(program: p1)
    expect(enrollments.second).to have_attributes(program: p2)
    expect(enrollments.last).to have_attributes(program: p3)
  end
end
