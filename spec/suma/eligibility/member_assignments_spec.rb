# frozen_string_literal: true

RSpec.describe Suma::Eligibility::MemberAssignment, :db do
  describe "to_sources" do
    it "describes all source types" do
      m = Suma::Fixtures.member.create
      o = Suma::Fixtures.organization.with_membership_of(m).create
      r = Suma::Fixtures.role.create
      o.add_role(r)
      m.add_role(r)

      attr = Suma::Fixtures.eligibility_attribute.create
      [m, o, r].each do |x|
        Suma::Fixtures.eligibility_assignment.create(assignee: x, attribute: attr)
      end
      expect(described_class.all).to have_length(4)

      ma = described_class.find!(member: m, source_type: "member")
      expect(ma.to_sources).to contain_exactly(be === m)

      ma = described_class.find!(member: m, source_type: "role")
      expect(ma.to_sources).to contain_exactly(be === r)

      ma = described_class.find!(member: m, source_type: "membership")
      expect(ma.to_sources).to contain_exactly(be === o.memberships.first)

      ma = described_class.find!(member: m, source_type: "organization_role")
      expect(ma.to_sources).to match_array([be === o, be === r])
    end
  end
end
