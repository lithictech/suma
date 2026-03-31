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

  it "creates an attribute for itself on create" do
    o = Suma::Fixtures.organization.create(name: "Acme")
    expect(o.eligibility_assignments).to have_length(1)
    attr = o.eligibility_assignments.first.attribute
    expect(attr.name).to eq("Acme")
    o.update(name: "Acme2")

    o2 = Suma::Fixtures.organization.create(name: "Acme")
    expect(o2.eligibility_assignments).to have_length(1)
    expect(o2.eligibility_assignments.first.attribute).to be === attr
  end
end
