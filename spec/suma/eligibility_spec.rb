# frozen_string_literal: true

RSpec.describe Suma::Eligibility, :db do
  it "does its thing" do
    member = Suma::Fixtures.member.create
    member2 = Suma::Fixtures.member.create
    org = Suma::Fixtures.organization.with_membership_of(member).create
    role1 = Suma::Fixtures.role.create
    role2 = Suma::Fixtures.role.create
    org.add_role(role1)
    member.add_role(role2)

    ami80 = Suma::Eligibility::Attribute.create(name: "80% AMI")
    ami60 = Suma::Eligibility::Attribute.create(name: "60% AMI", parent: ami80)
    ami40 = Suma::Eligibility::Attribute.create(name: "40% AMI", parent: ami60)
    ami20 = Suma::Eligibility::Attribute.create(name: "20% AMI", parent: ami40)

    Suma::Eligibility::Assignment.create(member: member2, attribute: ami60)

    Suma::Eligibility::Assignment.create(member:, attribute: ami20)
    Suma::Eligibility::Assignment.create(role: role1, attribute: ami40)
    Suma::Eligibility::Assignment.create(role: role2, attribute: ami60)
    Suma::Eligibility::Assignment.create(organization: org, attribute: ami80)

    trigger80 = Suma::Fixtures.payment_trigger.create(label: "Discount AMI 80%")
    trigger60 = Suma::Fixtures.payment_trigger.create(label: "Discount AMI 60%")
    trigger40 = Suma::Fixtures.payment_trigger.create(label: "Discount AMI 40%")
    trigger20 = Suma::Fixtures.payment_trigger.create(label: "Discount AMI 20%")

    req_ami80 = Suma::Eligibility::Requirement.create(payment_trigger: trigger80)
    req_ami80.expression.update(attribute: ami80)
    req_ami60 = Suma::Eligibility::Requirement.create(payment_trigger: trigger60)
    req_ami60.expression.update(attribute: ami60)
    req_ami40 = Suma::Eligibility::Requirement.create(payment_trigger: trigger40)
    req_ami40.expression.update(attribute: ami40)
    req_ami20 = Suma::Eligibility::Requirement.create(payment_trigger: trigger20)
    req_ami20.expression.update(attribute: ami20)

    ea = member.evaluate_eligibility_access_to(trigger20)
    expect(ea).to be_access
  end
end
