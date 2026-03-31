# frozen_string_literal: true

RSpec.describe Suma::Eligibility::Evaluation, :db do
  before(:each) do
    stub_const("Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE", false)
  end

  describe "evaluate" do
    it "evaluates eligibility" do
      member = Suma::Fixtures.member.create
      org = Suma::Fixtures.organization.with_membership_of(member).create
      role1 = Suma::Fixtures.role.create
      role2 = Suma::Fixtures.role.create
      org.add_role(role1)
      member.add_role(role2)

      member2 = Suma::Fixtures.member.create
      member2.add_role(role2)

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

      Suma::Fixtures.eligibility_requirement.of(trigger80).create.
        expression.update(type: "attribute", operator: nil, attribute: ami80)
      Suma::Fixtures.eligibility_requirement.of(trigger60).create.
        expression.update(type: "attribute", operator: nil, attribute: ami60)
      Suma::Fixtures.eligibility_requirement.of(trigger40).create.
        expression.update(type: "attribute", operator: nil, attribute: ami40)
      Suma::Fixtures.eligibility_requirement.of(trigger20).create.
        expression.update(type: "attribute", operator: nil, attribute: ami20)

      expect(member.evaluate_eligibility_access_to(trigger80)).to be_access
      expect(member.evaluate_eligibility_access_to(trigger20)).to be_access

      expect(member2.evaluate_eligibility_access_to(trigger60)).to be_access
      expect(member2.evaluate_eligibility_access_to(trigger80)).to be_access
      expect(member2.evaluate_eligibility_access_to(trigger40)).to_not be_access
    end

    it "uses boolean logic" do
      member = Suma::Fixtures.member.create
      role = Suma::Fixtures.role.create
      member.add_role(role)

      attr1 = Suma::Eligibility::Attribute.create(name: "Attr1")
      attr2 = Suma::Eligibility::Attribute.create(name: "Attr2")
      payment_trigger = Suma::Fixtures.payment_trigger.create

      expr = Suma::Fixtures.eligibility_requirement.of(payment_trigger).create.expression
      expr.update(
        left: Suma::Fixtures.eligibility_expression.attribute(attr1).create,
        right: Suma::Fixtures.eligibility_expression.attribute(attr2).create,
        operator: "OR",
      )

      # Using an OR should allow access
      Suma::Eligibility::Assignment.create(role:, attribute: attr1)
      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to be_access

      # AND is missing attr2
      expr.update(operator: "AND")
      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to_not be_access

      # We add attr2 so AND should work
      attr2_assignment = Suma::Eligibility::Assignment.create(role:, attribute: attr2)
      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to be_access

      # Remove attr2 again
      attr2_assignment.destroy
      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to_not be_access

      # Multiple requirements should work like OR
      Suma::Fixtures.eligibility_requirement.of(payment_trigger).create.expression.
        update(type: "attribute", attribute: attr1, operator: nil)
      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to be_access
    end

    it "uses boolean logic 2 (empty binary operand)" do
      member = Suma::Fixtures.member.create

      payment_trigger = Suma::Fixtures.payment_trigger.create(label: "trigger1")
      Suma::Fixtures.eligibility_requirement.of(payment_trigger).create.
        expression.
        update(
          left: nil,
          right: Suma::Fixtures.eligibility_expression.binary(
            "AND",
            [
              Suma::Fixtures.eligibility_expression.attribute("attr6").create,
            ],
          ).create,
        )

      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to_not be_access
    end

    it "uses boolean logic 3 (unary not)" do
      member = Suma::Fixtures.member.create
      attr = Suma::Fixtures.eligibility_attribute(name: "attr1").create
      Suma::Fixtures.eligibility_assignment.of(attr).to(member).create

      payment_trigger = Suma::Fixtures.payment_trigger.create(label: "trigger1")
      expr = Suma::Fixtures.eligibility_requirement.of(payment_trigger).create.expression

      expr.update(
        type: "unary",
        operator: "NOT",
        left: Suma::Fixtures.eligibility_expression.attribute(attr).create,
      )

      # NOT attr1
      expect(member.evaluate_eligibility_access_to(payment_trigger.refresh)).to_not be_access

      expr.update(
        type: "unary",
        operator: "NOT",
        left: Suma::Fixtures.eligibility_expression.unary(
          "NOT",
          Suma::Fixtures.eligibility_expression.attribute(attr).create,
        ).create,
      )
      # NOT NOT attr1
      payment_trigger.refresh
      expect(member.evaluate_eligibility_access_to(payment_trigger)).to be_access
    end

    describe "when default accessible is true" do
      before(:each) do
        stub_const("Suma::Eligibility::RESOURCES_DEFAULT_ACCESSIBLE", true)
      end

      it "is true for a resource without requirements" do
        member = Suma::Fixtures.member.create
        program = Suma::Fixtures.program.create

        expect(member.evaluate_eligibility_access_to(program)).to be_access
        Suma::Fixtures.eligibility_requirement.of(program).create
        expect(member.evaluate_eligibility_access_to(program)).to_not be_access
      end
    end
  end

  it "can represent itself" do
    member = Suma::Fixtures.member.create
    org = Suma::Fixtures.organization.with_membership_of(member).create(name: "Org1")
    membership = org.memberships.first
    role1 = Suma::Fixtures.role.create(name: "role1")
    role2 = Suma::Fixtures.role.create(name: "role2")
    org.add_role(role1)
    member.add_role(role2)

    member2 = Suma::Fixtures.member.create
    member2.add_role(role2)

    attr1 = Suma::Eligibility::Attribute.create(name: "attr1")
    attr2 = Suma::Eligibility::Attribute.create(name: "attr2", parent: attr1)
    attr3 = Suma::Eligibility::Attribute.create(name: "attr3", parent: attr2)
    attr4 = Suma::Eligibility::Attribute.create(name: "attr4", parent: attr3)
    attr5 = Suma::Eligibility::Attribute.create(name: "attr5", parent: attr3)

    Suma::Eligibility::Assignment.create(member: member2, attribute: attr2)

    Suma::Eligibility::Assignment.create(member:, attribute: attr4)
    Suma::Eligibility::Assignment.create(role: role1, attribute: attr3)
    Suma::Eligibility::Assignment.create(role: role1, attribute: attr2)
    Suma::Eligibility::Assignment.create(role: role2, attribute: attr2)
    Suma::Eligibility::Assignment.create(organization: org, attribute: attr1)

    trigger1 = Suma::Fixtures.payment_trigger.create(label: "trigger1")

    Suma::Fixtures.eligibility_requirement.of(trigger1).create.
      expression.
      update(
        left: Suma::Fixtures.eligibility_expression.attribute(attr1).create,
        right: Suma::Fixtures.eligibility_expression.binary(
          "OR",
          [
            Suma::Fixtures.eligibility_expression.attribute(attr2).create,
            Suma::Fixtures.eligibility_expression.binary(
              "AND",
              [
                Suma::Fixtures.eligibility_expression.
                  unary(
                    "NOT",
                    Suma::Fixtures.eligibility_expression.attribute(attr3).create,
                  ).create,
                Suma::Fixtures.eligibility_expression.attribute(attr4).create,
              ],
            ).create,
          ],
        ).create,
      )
    Suma::Fixtures.eligibility_requirement.of(trigger1).create.
      expression.
      update(
        left: nil,
        right: Suma::Fixtures.eligibility_expression.binary(
          "AND",
          [
            Suma::Fixtures.eligibility_expression.attribute("attr6").create,
          ],
        ).create,
      )

    evaled = member.evaluate_eligibility_access_to(trigger1)

    txt_tbl = evaled.to_ascii_tables
    expect(txt_tbl[:expressions]).to eq(<<~STR.strip)
      +--------------------------------------------------------+--------+
      | Expression                                             | Result |
      +--------------------------------------------------------+--------+
      | 'attr6'                                                | fail   |
      | ('attr1' AND ('attr2' OR ((NOT 'attr3') AND 'attr4'))) | PASS   |
      +--------------------------------------------------------+--------+
    STR
    expect(txt_tbl[:assignments]).to eq(<<~STR.strip)
      +-------------------------+---------------------+-------+
      | Attribute               | From                | Depth |
      +-------------------------+---------------------+-------+
      | attr1                   | membership in Org1  | 0     |
      | attr1                   | role role1 for Org1 | 1     |
      | attr1                   | role role1 for Org1 | 2     |
      | attr1                   | role role2          | 1     |
      | attr1                   | self                | 3     |
      | attr2.attr1             | role role1 for Org1 | 0     |
      | attr2.attr1             | role role1 for Org1 | 1     |
      | attr2.attr1             | role role2          | 0     |
      | attr2.attr1             | self                | 2     |
      | attr3.attr2.attr1       | role role1 for Org1 | 0     |
      | attr3.attr2.attr1       | self                | 1     |
      | attr4.attr3.attr2.attr1 | self                | 0     |
      +-------------------------+---------------------+-------+
    STR

    struct_tbl = evaled.to_structured_tables
    expect(struct_tbl[:expressions]).to match_array(
      [
        have_attributes(formula: "'attr6'", passed: false),
        have_attributes(formula: "('attr1' AND ('attr2' OR ((NOT 'attr3') AND 'attr4')))", passed: true),
      ],
    )
    expect(struct_tbl[:assignments]).to match_array(
      [
        have_attributes(
          attribute_id: attr1.id,
          label: "attr1",
          depth: 0,
          source_type: "membership",
          sources: [
            {
              id: membership.id,
              label: "Membership #{membership.id}",
              admin_link: "http://localhost:22014/membership/#{membership.id}",
            },
          ],
        ),
        have_attributes(label: "attr1", depth: 1, source_type: "organization_role"),
        have_attributes(label: "attr1", depth: 1, source_type: "role"),
        have_attributes(label: "attr1", depth: 2, source_type: "organization_role"),
        have_attributes(label: "attr1", depth: 3, source_type: "member"),
        have_attributes(label: "attr2.attr1", depth: 0, source_type: "organization_role"),
        have_attributes(label: "attr2.attr1", depth: 0, source_type: "role"),
        have_attributes(label: "attr2.attr1", depth: 1, source_type: "organization_role"),
        have_attributes(label: "attr2.attr1", depth: 2, source_type: "member"),
        have_attributes(label: "attr3.attr2.attr1", depth: 0, source_type: "organization_role"),
        have_attributes(label: "attr3.attr2.attr1", depth: 1, source_type: "member"),
        have_attributes(label: "attr4.attr3.attr2.attr1", depth: 0, source_type: "member"),
      ],
    )
  end
end
