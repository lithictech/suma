# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.create }
  let(:now) { Time.now }

  it "can represent a blank/empty member" do
    d = described_class.new(member, at: now)
    expect(d).to have_attributes(vendor_services: [], offerings: [])
  end

  it "includes vendible groupings for eligible vendor services and offerings" do
    vs = Suma::Fixtures.vendor_service.mobility.create
    off = Suma::Fixtures.offering.create
    vg1 = Suma::Fixtures.vendible_group.with(vs).create
    vg2 = Suma::Fixtures.vendible_group.with(off).create
    expect(described_class.new(member, at: now)).to have_attributes(
      offerings: have_same_ids_as(off),
      vendor_services: have_same_ids_as(vs),
      vendible_groupings: contain_exactly(
        have_attributes(group: vg1),
        have_attributes(group: vg2),
      ),
    )
  end
end
