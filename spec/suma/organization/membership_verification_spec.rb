# frozen_string_literal: true

RSpec.describe "Suma::Organization::MembershipVerification", :db do
  let(:described_class) { Suma::Organization::MembershipVerification }

  it "can fixture itself" do
    expect { Suma::Fixtures.organization_membership_verification.create }.to_not raise_error
  end

  it "has relations" do
    v = Suma::Fixtures.organization_membership_verification.create
    expect(v.membership.verification).to be === v
    expect(v.audit_logs).to be_empty
  end

  describe "state machines" do
    it "can perform simple transitions" do
      v = Suma::Fixtures.organization_membership_verification.create
      expect(v).to transition_on(:start).to("in_progress")
      expect(v).to transition_on(:abandon).to("abandoned")
      expect(v).to transition_on(:resume).to("in_progress")
      v.status = "in_progress"
      expect(v).to transition_on(:reject).to("ineligible")
      v.status = "in_progress"
      expect(v).to transition_on(:approve).to("verified")
    end
  end
end
