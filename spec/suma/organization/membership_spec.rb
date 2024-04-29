# frozen_string_literal: true

RSpec.describe "Suma::Organization::Membership", :db do
  let(:described_class) { Suma::Organization::Membership }

  it "can fixture itself" do
    expect(Suma::Fixtures.organization_membership.verified.create).to have_attributes(verified_member: be_present)
    expect(Suma::Fixtures.organization_membership.unverified.create).to have_attributes(unverified_member: be_present)
    expect { Suma::Fixtures.organization_membership.create }.to raise_error(/must call/)
  end

  describe "validations" do
    it "can only have verified or unverified set" do
      o = Suma::Fixtures.organization.create
      expect do
        described_class.create(
          organization: o,
          verified_member: Suma::Fixtures.member.create,
          unverified_member: Suma::Fixtures.member.create,
        )
      end.to raise_error(/unambiguous_member/)
    end
  end
end
