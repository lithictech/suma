# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.create }
  let(:now) { Time.now }

  it "can represent a blank/empty member" do
    d = described_class.new(member, at: now)
    expect(d).to have_attributes(vendor_services: [], offerings: [])
  end

  it "includes programs for eligible vendor services and offerings" do
    vs = Suma::Fixtures.vendor_service.mobility.create
    off = Suma::Fixtures.offering.create
    prog1 = Suma::Fixtures.program.with_(vs).create
    prog2 = Suma::Fixtures.program.with_(off).create
    Suma::Fixtures.program_enrollment.create(program: prog1, member:)
    Suma::Fixtures.program_enrollment.create(program: prog2, member:)
    expect(described_class.new(member, at: now)).to have_attributes(
      offerings: have_same_ids_as(off),
      vendor_services: have_same_ids_as(vs),
      programs: have_same_ids_as(prog1, prog2),
    )
  end
end
