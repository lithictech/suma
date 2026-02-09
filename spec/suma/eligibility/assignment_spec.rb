# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Assignment", :db do
  let(:described_class) { Suma::Eligibility::Assignment }

  it "can be fixtured" do
    attr = Suma::Fixtures.eligibility_attribute.create
    m = Suma::Fixtures.member.create
    ea = Suma::Fixtures.eligibility_assignment.of(attr).to(m).create
    expect(ea).to have_attributes(attribute: be === attr, assignee: be === m)
  end

  it "can set and get an assignee" do
    ea = Suma::Fixtures.eligibility_assignment.create
    m = Suma::Fixtures.member.create
    o = Suma::Fixtures.organization.create
    r = Suma::Fixtures.role.create
    ea.assignee = m
    expect(ea).to have_attributes(member: be === m, organization: be_nil, role: be_nil, assignee: be === m)
    ea.assignee = o
    expect(ea).to have_attributes(member: be_nil, organization: be === o, role: be_nil, assignee: be === o)
    ea.assignee = r
    expect(ea).to have_attributes(member: be_nil, organization: be_nil, role: be === r, assignee: be === r)
    ea.assignee = nil
    expect(ea).to have_attributes(member: be_nil, organization: be_nil, role: be_nil, assignee: be_nil)
    expect { ea.assignee = 5 }.to raise_error(TypeError, /invalid association type: Integer\(5\)/)
  end
end
