# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Expression", :db do
  let(:described_class) { Suma::Eligibility::Expression }

  it "can be fixtured" do
    e = Suma::Fixtures.eligibility_expression.create
    expect(e).to be_a(described_class)
    expect(e.attribute).to be_nil

    e = Suma::Fixtures.eligibility_expression.attribute.create
    expect(e.attribute).to be_a(Suma::Eligibility::Attribute)

    e = Suma::Fixtures.eligibility_expression.binary("AND").create
    expect(e).to have_attributes(attribute: nil, operator: "AND", left: nil, right: nil)

    e = Suma::Fixtures.eligibility_expression.binary("AND", [{}, {}]).create
    expect(e).to have_attributes(type: "binary", operator: "AND")
    expect(e.left).to be_a(Suma::Eligibility::Expression)
    expect(e.right).to be_a(Suma::Eligibility::Expression)

    e2 = Suma::Fixtures.eligibility_expression.create
    e = Suma::Fixtures.eligibility_expression.binary("AND", [nil, e2]).create
    expect(e.left).to be_nil
    expect(e.right).to be === e2

    e = Suma::Fixtures.eligibility_expression.unary("NOT", e2).create
    expect(e).to have_attributes(type: "unary", operator: "NOT")
    expect(e.left).to be === e2
    expect(e.right).to be_nil
  end

  it "knows about type properties" do
    attr = Suma::Fixtures.eligibility_expression.attribute.create
    expect(attr).to have_attributes(type: "attribute", attribute?: true)
    binary = Suma::Fixtures.eligibility_expression.binary.create
    expect(binary).to have_attributes(type: "binary", binary?: true)
    unary = Suma::Fixtures.eligibility_expression.unary.create
    expect(unary).to have_attributes(type: "unary", unary?: true)
  end

  it "recursively finds attributes" do
    a1 = Suma::Fixtures.eligibility_attribute.create
    a2 = Suma::Fixtures.eligibility_attribute.create
    a3 = Suma::Fixtures.eligibility_attribute.create
    expr_fac = Suma::Fixtures.eligibility_expression
    e = expr_fac.binary("AND").create(
      left: expr_fac.binary("AND").create(
        left: expr_fac.attribute(a1).create,
        right: expr_fac.binary("AND").create(
          right: expr_fac.attribute(a2).create,
        ),
      ),
      right: expr_fac.unary("NOT", expr_fac.attribute(a3).create).create,
    )
    expect(e.referenced_attributes).to have_same_ids_as(a1, a2, a3)
  end

  it "can calculate formula strings" do
    expr_fac = Suma::Fixtures.eligibility_expression
    empty = expr_fac.create
    expect(empty.to_formula_str).to eq("")
    attrexpr = expr_fac.attribute({name: "foo"}).create
    expect(attrexpr.to_formula_str).to eq("'foo'")

    empty_operand = expr_fac.binary("AND").create
    expect(empty_operand.to_formula_str).to eq("")

    single_side = expr_fac.and.create(right: expr_fac.attribute("foo1").create)
    expect(single_side.to_formula_str).to eq("'foo1'")

    deep = expr_fac.and.create(
      left: expr_fac.attribute("foo2").create,
      right: expr_fac.or.create(
        left: expr_fac.and.create(
          left: expr_fac.attribute("foo3").create,
          right: expr_fac.attribute("foo4").create,
        ),
      ),
    )
    expect(deep.to_formula_str).to eq("('foo2' AND ('foo3' AND 'foo4'))")
  end
end
