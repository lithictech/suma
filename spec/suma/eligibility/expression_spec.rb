# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Expression", :db do
  let(:described_class) { Suma::Eligibility::Expression }

  it "can be fixtured" do
    e = Suma::Fixtures.eligibility_expression.create
    expect(e).to be_a(described_class)
    expect(e.attribute).to be_nil

    e = Suma::Fixtures.eligibility_expression.leaf.create
    expect(e.attribute).to be_a(Suma::Eligibility::Attribute)

    e = Suma::Fixtures.eligibility_expression.branch.create
    expect(e).to have_attributes(attribute: nil, left: nil, right: nil)

    e = Suma::Fixtures.eligibility_expression.branch([{}, {}]).create
    expect(e.left).to be_a(Suma::Eligibility::Expression)
    expect(e.right).to be_a(Suma::Eligibility::Expression)

    e2 = Suma::Fixtures.eligibility_expression.create
    e = Suma::Fixtures.eligibility_expression.branch([nil, e2]).create
    expect(e.left).to be_nil
    expect(e.right).to be === e2
  end

  it "knows about leaf and branch properties" do
    leaf = Suma::Fixtures.eligibility_expression.leaf.create
    expect(leaf).to have_attributes(type: :leaf, leaf?: true)
    branch = Suma::Fixtures.eligibility_expression.branch.create
    expect(branch).to have_attributes(type: :branch, branch?: true)
  end

  it "recursively finds attributes" do
    a1 = Suma::Fixtures.eligibility_attribute.create
    a2 = Suma::Fixtures.eligibility_attribute.create
    a3 = Suma::Fixtures.eligibility_attribute.create
    expr_fac = Suma::Fixtures.eligibility_expression
    e = expr_fac.create(
      left: expr_fac.create(
        left: expr_fac.leaf(a1).create,
        right: expr_fac.create(
          right: expr_fac.leaf(a2).create,
        ),
      ),
      right: expr_fac.leaf(a3).create,
    )
    expect(e.referenced_attributes).to have_same_ids_as(a1, a2, a3)
  end

  it "can calculate formula strings" do
    expr_fac = Suma::Fixtures.eligibility_expression
    empty = expr_fac.create
    expect(empty.to_formula_str).to eq("")
    leaf = expr_fac.leaf({name: "foo"}).create
    expect(leaf.to_formula_str).to eq("'foo'")

    empty_operand = expr_fac.create(left: expr_fac.create, right: expr_fac.create)
    expect(empty_operand.to_formula_str).to eq("")

    single_side = expr_fac.create(right: expr_fac.leaf({name: "foo1"}).create)
    expect(single_side.to_formula_str).to eq("'foo1'")

    deep = expr_fac.and.create(
      left: expr_fac.leaf({name: "foo2"}).create,
      right: expr_fac.or.create(
        left: expr_fac.create(
          left: expr_fac.leaf({name: "foo3"}).create,
          right: expr_fac.leaf({name: "foo4"}).create,
        ),
      ),
    )
    expect(deep.to_formula_str).to eq("('foo2' AND ('foo3' AND 'foo4'))")
  end
end
