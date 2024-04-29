# frozen_string_literal: true

RSpec.describe "Suma::Organization::Membership", :db do
  let(:described_class) { Suma::Organization::Membership }

  it "can fixture itself" do
    expect(Suma::Fixtures.organization_membership.verified.create).to be_verified
    expect(Suma::Fixtures.organization_membership.unverified.create).to_not be_verified
    expect { Suma::Fixtures.organization_membership.create }.to raise_error(/must call/)
  end

  describe "validations" do
    it "can only have verified or unverified set" do
      o = Suma::Fixtures.organization.create
      expect do
        described_class.create(
          verified_organization: o,
          unverified_organization_name: "hi",
          member: Suma::Fixtures.member.create,
        )
      end.to raise_error(/unambiguous_verification_status/)
    end
  end
end
