# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.with_cash_ledger.create }
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
end
