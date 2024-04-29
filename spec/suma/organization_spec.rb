# frozen_string_literal: true

RSpec.describe "Suma::Organization", :db do
  let(:described_class) { Suma::Organization }

  it "can fixture an organization and members" do
    verified = Suma::Fixtures.member.create
    unverified = Suma::Fixtures.member.create
    org = Suma::Fixtures.organization(name: "Hacienda ABC").
      with_verified_membership(verified).
      with_unverified_membership(unverified).
      create
    expect(org).to have_attributes(name: "Hacienda ABC")
    expect(org.verified_memberships).to contain_exactly(have_attributes(verified_member: be === verified))
    expect(org.unverified_memberships).to contain_exactly(have_attributes(unverified_member: be === unverified))
  end
end
