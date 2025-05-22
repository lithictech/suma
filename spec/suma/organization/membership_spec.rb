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

  describe "remove_from_organization" do
    it "sets the former org to the verified org and sets verified org nil" do
      org = Suma::Fixtures.organization.create
      m = Suma::Fixtures.organization_membership.verified(org).create
      m.remove_from_organization
      expect(m).to have_attributes(
        verified_organization: nil,
        former_organization: be === org,
        formerly_in_organization_at: match_time(:now),
      )
    end

    it "errors if there is no verified org" do
      m = Suma::Fixtures.organization_membership.unverified.create
      expect { m.remove_from_organization }.to raise_error(Suma::InvalidPrecondition)
    end
  end

  it "has accessors about verified status" do
    m = Suma::Fixtures.organization_membership.unverified.create
    expect(m).to be_unverified
    expect(m).to_not be_verified
    expect(m).to_not be_removed
    m.verified_organization = Suma::Fixtures.organization.create
    expect(m).to_not be_unverified
    expect(m).to be_verified
    expect(m).to_not be_removed
    m.remove_from_organization
    expect(m).to_not be_unverified
    expect(m).to_not be_verified
    expect(m).to be_removed
  end

  describe "matched_organization" do
    it "finds an org with the unverified name" do
      o = Suma::Fixtures.organization.create
      m = Suma::Fixtures.organization_membership.unverified.create
      expect(m.matched_organization).to be_nil
      m.unverified_organization_name = o.name
      expect(m.matched_organization).to be === o
      m.verified_organization = o
      expect(m.matched_organization).to be_nil
    end
  end

  describe "after_save" do
    it "ensures the member is onboarding verified when the membership is verified" do
      m = Suma::Fixtures.organization_membership.unverified.create
      expect(m.member).to_not be_onboarding_verified
      m.update(verified_organization: Suma::Fixtures.organization.create)
      expect(m.member).to be_onboarding_verified
      expect(m.member.refresh).to be_onboarding_verified
    end

    it "ensures the member is verified if the membership is created as verified" do
      m = Suma::Fixtures.organization_membership.verified.create
      expect(m.member).to be_onboarding_verified
    end

    it "noops on an already verified member" do
      t = Time.parse("2020-01-01T00:00:00Z")
      member = Suma::Fixtures.member.create(onboarding_verified_at: t)
      m = Suma::Fixtures.organization_membership.verified.create(member:)
      expect(member.onboarding_verified_at).to eq(t)
    end

    it "does not verify the member if membership is not verified" do
      m = Suma::Fixtures.organization_membership.unverified.create
      expect(m.member).to_not be_onboarding_verified
      m.update(
        former_organization: Suma::Fixtures.organization.create,
        formerly_in_organization_at: Time.now,
        unverified_organization_name: nil,
      )
      expect(m.member).to_not be_onboarding_verified
    end
  end
end
