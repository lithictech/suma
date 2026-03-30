# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Expression::Serializer", :db do
  let(:described_class) { Suma::Eligibility::Expression::Serializer }

  def roundtrip(e)
    eser = e.serialize
    e2 = described_class.deserialize(eser)
    e2ser = e2.serialize
    expect(e2ser.to_h).to(eq(e.serialize.to_h))
  end

  it "can serialize and deserialize" do
    attr1 = Suma::Fixtures.eligibility_attribute.create(name: "A")
    attr2 = Suma::Fixtures.eligibility_attribute.create(name: "B", parent: attr1)
    expr_fac = Suma::Fixtures.eligibility_expression
    empty = expr_fac.create
    expect(empty.serialize.to_h).to eq({op: "AND"})
    attrexpr = expr_fac.attribute(attr1).create
    expect(attrexpr.serialize.to_h).to eq({attr: attr1.id, name: "A", fqn: "A"})
    roundtrip(attrexpr)

    empty_operand = expr_fac.binary("AND", [expr_fac.create, expr_fac.create]).create
    expect(empty_operand.serialize.to_h).to eq({left: {op: "AND"}, op: "AND", right: {op: "AND"}})
    roundtrip(empty_operand)

    single_side = expr_fac.binary("AND", [nil, expr_fac.attribute(attr1).create]).create
    expect(single_side.serialize.to_h).to eq({op: "AND", right: {attr: attr1.id, name: "A", fqn: "A"}})
    roundtrip(single_side)

    deep = expr_fac.and.create(
      left: expr_fac.attribute(attr1).create,
      right: expr_fac.not.create(
        left: expr_fac.or.create(
          left: expr_fac.attribute(attr1).create,
          right: expr_fac.attribute(attr2).create,
        ),
      ),
    )
    expect(deep.serialize.to_h).to match(
      {
        left: include(attr: attr1.id),
        op: "AND",
        right: {
          left: {
            left: include(attr: attr1.id),
            op: "OR",
            right: include(attr: attr2.id),
          },
          op: "NOT",
        },
      },
    )
    roundtrip(deep)
  end

  it "ignores missing attributes on deserialization" do
    expect(described_class.deserialize({attr: 0}).serialize.to_h).to eq({op: "AND"})

    attr = Suma::Fixtures.eligibility_attribute.create(name: "x")
    h = {
      left: {attr: 0, fqn: "z", name: "z"},
      op: "AND",
      right: {
        left: {
          left: {attr: attr.id, fqn: "x", name: "x"},
          op: "AND",
          right: {attr: 0, fqn: "a", name: "a"},
        },
        op: "OR",
      },
    }
    expect(described_class.deserialize(h).serialize.to_h).to eq(
      {
        op: "AND",
        right: {
          left: {
            left: {attr: attr.id, fqn: "x", name: "x"},
            op: "AND",
          },
          op: "OR",
        },
      },
    )
  end
end
