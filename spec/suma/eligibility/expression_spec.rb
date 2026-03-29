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

  describe "serialization" do
    def roundtrip(e)
      expect(described_class::Serializer.deserialize(e.serialize).serialize).to(eq(e.serialize))
    end

    it "can serialize and deserialize" do
      attr1 = Suma::Fixtures.eligibility_attribute.create(name: "A")
      attr2 = Suma::Fixtures.eligibility_attribute.create(name: "B", parent: attr1)
      expr_fac = Suma::Fixtures.eligibility_expression
      empty = expr_fac.create
      expect(empty.serialize).to eq({op: "AND"})
      attrexpr = expr_fac.attribute(attr1).create
      expect(attrexpr.serialize).to eq({attr: attr1.id, name: "A", fqn: "A"})
      roundtrip(attrexpr)

      empty_operand = expr_fac.binary("AND", [expr_fac.create, expr_fac.create]).create
      expect(empty_operand.serialize).to eq({left: {op: "AND"}, op: "AND", right: {op: "AND"}})
      roundtrip(empty_operand)

      single_side = expr_fac.binary("AND", [nil, expr_fac.attribute(attr1).create]).create
      expect(single_side.serialize).to eq({op: "AND", right: {attr: attr1.id, name: "A", fqn: "A"}})
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
      expect(deep.serialize).to match(
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
      expect(described_class::Serializer.deserialize({attr: 0}).serialize).to eq({op: "AND"})

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
      expect(described_class::Serializer.deserialize(h).serialize).to eq(
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

  describe "tokenization" do
    it "can convert a serialized expression into tokens" do
      ser = {
        left: {attr: 5, name: "A", fqn: "A.B"},
        op: "AND",
        right: {
          left: {
            left: {attr: 5, name: "A", fqn: "A.B"},
            op: "AND",
            right: {attr: 6, name: "B", fqn: "B"},
          },
          op: "OR",
        },
      }
      tokens = described_class::Tokenizer.tokenize(ser)
      expect(tokens.map(&:value).join(" ")).to eq("A.B AND ( ( A.B AND B ) OR )")
      expect(tokens.map(&:to_h)).to match_array(
        [
          {id: 5, label: "A", type: :variable, value: "A.B"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "(", label: "(", type: :paren, value: "("},
          {id: 5, label: "A", type: :variable, value: "A.B"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: 6, label: "B", type: :variable, value: "B"},
          {id: ")", label: ")", type: :paren, value: ")"},
          {id: "OR", label: "OR", type: :operator, value: "OR"},
          {id: ")", label: ")", type: :paren, value: ")"},
        ],
      )
    end

    it "can parse tokens as a serialized expression" do
      tokens = [
        {id: 5, label: "A", type: :variable, value: "A.B"},
        {id: "AND", label: "AND", type: :operator, value: "AND"},
        {id: "(", label: "(", type: :paren, value: "("},
        {id: "(", label: "(", type: :paren, value: "("},
        {id: 5, label: "A", type: :variable, value: "A.B"},
        {id: "AND", label: "AND", type: :operator, value: "AND"},
        {id: 6, label: "B", type: :variable, value: "B"},
        {id: ")", label: ")", type: :paren, value: ")"},
        {id: "OR", label: "OR", type: :operator, value: "OR"},
        {id: 6, label: "B", type: :variable, value: "B"},
        {id: ")", label: ")", type: :paren, value: ")"},
      ].map { |t| described_class::Tokenizer::Token.new(**t) }
      result = described_class::Tokenizer.detokenize(tokens)
      expect(result.warnings).to eq([])
      expect(result.serialized).to eq(
        {
          left: {attr: 5, name: "A", fqn: "A.B"},
          op: "AND",
          right: {
            left: {
              left: {attr: 5, name: "A", fqn: "A.B"},
              op: "AND",
              right: {attr: 6, name: "B", fqn: "B"},
            },
            op: "OR",
            right: {attr: 6, name: "B", fqn: "B"},
          },
        },
      )
    end

    it "handles partially valid expressions" do
      tokens = [
        {id: 5, label: "A", type: :variable, value: "A.B"},
        {id: "AND", label: "AND", type: :operator, value: "AND"},
        {id: "(", label: "(", type: :paren, value: "("},
        {id: "(", label: "(", type: :paren, value: "("},
        {id: 5, label: "A", type: :variable, value: "A.B"},
        {id: "AND", label: "AND", type: :operator, value: "AND"},
        {id: 6, label: "B", type: :variable, value: "B"},
        {id: ")", label: ")", type: :paren, value: ")"},
        {id: "OR", label: "OR", type: :operator, value: "OR"},
        {id: ")", label: ")", type: :paren, value: ")"},
      ].map { |t| described_class::Tokenizer::Token.new(**t) }
      result = described_class::Tokenizer.detokenize(tokens)
      expect(result.warnings.map(&:to_s)).to eq(["operator before ) is invalid: (9)"])
      expect(result.serialized).to eq(
        {
          left: {attr: 5, name: "A", fqn: "A.B"},
          op: "AND",
          right: {
            left: {
              left: {attr: 5, name: "A", fqn: "A.B"},
              op: "AND",
              right: {attr: 6, name: "B", fqn: "B"},
            },
            op: "OR",
          },
        },
      )
    end

    it "handles empty tokens" do
      result = described_class::Tokenizer.detokenize([])
      expect(result.warnings.map(&:to_s)).to eq([])
      expect(result.serialized).to eq({})
    end

    it "handles single attribute tokens" do
      tokens = [
        {id: 5, label: "A", type: :variable, value: "A.B"},
      ].map { |t| described_class::Tokenizer::Token.new(**t) }
      result = described_class::Tokenizer.detokenize(tokens)
      expect(result.warnings.map(&:to_s)).to eq([])
      expect(result.serialized).to eq({attr: 5, fqn: "A.B", name: "A"})
    end

    it "uses empty for the empty form" do
      expr = Suma::Fixtures.eligibility_expression.create
      expect(expr.tokenize).to eq([])
    end

    describe "validity" do
      it "fails for invalid types" do
        tokens = [
          {id: "AND", label: "AND", type: :foo, value: "AND"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["invalid type: (0) foo"])
      end

      it "fails for missing close parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["unmatched opening parenthesis: (0)"])
      end

      it "fails for missing open parens" do
        tokens = [
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["unmatched closing parenthesis: (0)"])
      end

      it "fails for empty parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["empty parentheses are not allowed: (0)"])
      end

      it "fails for invalid paren values" do
        tokens = [
          {id: "x", label: "(", type: :paren, value: "("},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["invalid parenthesis id: (0) x"])
      end

      it "fails for invalid operators" do
        tokens = [
          {id: "x", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["invalid operator id: (0) x"])
      end

      it "fails for misplaced operators" do
        tokens = [
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: 5, label: "A", type: :variable, value: "A.B"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["cannot appear here: (0) AND"])
      end

      it "fails for closing operators" do
        tokens = [
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["expression cannot end with operator: (1) AND"])
      end

      it "fails for missing operators" do
        tokens = [
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "x", label: "x", type: :variable, value: "x"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["operator required before variable: (1) x"])
      end

      it "fails for operators before parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Tokenizer::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["operator before ) is invalid: (3)"])
      end
    end
  end
end
