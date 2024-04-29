# frozen_string_literal: true

RSpec.describe "Suma::Organization", :db do
  let(:described_class) { Suma::Organization }

  it "can fixture an organization and members" do
    m = Suma::Fixtures.member.create
    org = Suma::Fixtures.organization(name: "Hacienda ABC").
      with_membership_of(m).
      create
    expect(org).to have_attributes(name: "Hacienda ABC")
    expect(org.memberships).to contain_exactly(have_attributes(member: be === m))
  end
end
