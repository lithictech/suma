# frozen_string_literal: true

RSpec.describe Suma::Eligibility::MemberAssignment, :db do
  describe "associations" do
    it "has an association to attributes" do
      member = Suma::Fixtures.member.create
      attr = Suma::Fixtures.eligibility_attribute.create
      Suma::Fixtures.eligibility_assignment.of(attr).to(member).create
      expect(described_class.all).to have_length(1)
      mea = described_class.first
      expect(mea.member).to be === member
      expect(mea.attribute).to be === attr
      expect(member.expanded_eligibility_assignments).to include(be === mea)
    end

    describe "sources" do
      it "describes all source types" do
        m = Suma::Fixtures.member.create
        o = Suma::Fixtures.organization.with_membership_of(m).create
        membership = o.memberships.first
        o.eligibility_assignments_dataset.delete # Remove the auto-created one for simplicity during testing
        r = Suma::Fixtures.role.create
        o.add_role(r)
        m.add_role(r)

        attr = Suma::Fixtures.eligibility_attribute.create
        [m, o, r].each do |x|
          Suma::Fixtures.eligibility_assignment.create(assignee: x, attribute: attr)
        end
        expect(described_class.all).to have_length(4)

        ma = described_class.find!(member: m, source_type: "member")
        expect(ma.sources).to contain_exactly(be === m)

        ma = described_class.find!(member: m, source_type: "role")
        expect(ma.sources).to contain_exactly(be === r)

        ma = described_class.find!(member: m, source_type: "membership")
        expect(ma.sources).to contain_exactly(be === o.memberships.first)

        ma = described_class.find!(member: m, source_type: "organization_role")
        expect(ma.sources).to match_array([be === membership, be === r])

        ma = described_class.where(member: m, source_type: "organization_role").all.first
        expect(ma.sources).to match_array([be === membership, be === r])
      end
    end
  end
end
