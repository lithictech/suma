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

    single_side = expr_fac.create(right: expr_fac.leaf("foo1").create)
    expect(single_side.to_formula_str).to eq("'foo1'")

    deep = expr_fac.and.create(
      left: expr_fac.leaf("foo2").create,
      right: expr_fac.or.create(
        left: expr_fac.create(
          left: expr_fac.leaf("foo3").create,
          right: expr_fac.leaf("foo4").create,
        ),
      ),
    )
    expect(deep.to_formula_str).to eq("('foo2' AND ('foo3' AND 'foo4'))")
  end

  describe "serialization" do
    def roundtrip(e)
      expect(described_class.deserialize(e.serialize).serialize).to(eq(e.serialize))
    end

    it "can serialize and deserialize" do
      attr1 = Suma::Fixtures.eligibility_attribute.create(name: "A")
      attr2 = Suma::Fixtures.eligibility_attribute.create(name: "B", parent: attr1)
      expr_fac = Suma::Fixtures.eligibility_expression
      empty = expr_fac.create
      expect(empty.serialize).to eq({op: "AND"})
      leaf = expr_fac.leaf(attr1).create
      expect(leaf.serialize).to eq({attr: attr1.id, name: "A", fqn: "A"})
      roundtrip(leaf)

      empty_operand = expr_fac.create(left: expr_fac.create, right: expr_fac.create)
      expect(empty_operand.serialize).to eq({left: {op: "AND"}, op: "AND", right: {op: "AND"}})
      roundtrip(empty_operand)

      single_side = expr_fac.create(right: expr_fac.leaf(attr1).create)
      expect(single_side.serialize).to eq({op: "AND", right: {attr: attr1.id, name: "A", fqn: "A"}})
      roundtrip(single_side)

      deep = expr_fac.and.create(
        left: expr_fac.leaf(attr1).create,
        right: expr_fac.or.create(
          left: expr_fac.create(
            left: expr_fac.leaf(attr1).create,
            right: expr_fac.leaf(attr2).create,
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
              op: "AND",
              right: include(attr: attr2.id),
            },
            op: "OR",
          },
        },
      )
      roundtrip(deep)
    end

    it "ignores missing attributes on deserialization" do
      expect(described_class.deserialize({attr: 0}).serialize).to eq({op: "AND"})

      attr = Suma::Fixtures.eligibility_attribute.create
      h = {
        left: {attr: 0},
        op: "AND",
        right: {
          left: {
            left: {attr: attr.id},
            op: "AND",
            right: {attr: 0},
          },
          op: "OR",
        },
      }
      expect(described_class.deserialize(h).serialize).to eq(
        {
          op: "AND",
          right: {
            left: {
              left: {attr: attr.id},
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
        {id: ")", label: ")", type: :paren, value: ")"},
      ].map { |t| described_class::Token.new(**t) }
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
          },
        },
      )
    end

    it "handles empty tokens" do
      result = described_class::Tokenizer.detokenize([])
      expect(result.warnings).to eq([])
      expect(result.serialized).to eq({})
    end

    describe "validity" do
      it "fails for invalid types" do
        tokens = [
          {id: "AND", label: "AND", type: :foo, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Invalid type 'foo'"])
      end

      it "fails for missing close parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Unmatched opening parenthesis"])
      end

      it "fails for missing open parens" do
        tokens = [
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Unmatched closing parenthesis"])
      end

      it "fails for empty parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Empty parentheses are not allowed"])
      end

      it "fails for invalid paren values" do
        tokens = [
          {id: "x", label: "(", type: :paren, value: "("},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Invalid parenthesis id 'x'"])
      end

      it "fails for invalid operators" do
        tokens = [
          {id: "x", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Invalid operator id 'x'"])
      end

      it "fails for misplaced operators" do
        tokens = [
          {id: "AND", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["'AND' cannot appear here"])
      end

      it "fails for closing operators" do
        tokens = [
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Expression cannot end with 'AND'"])
      end

      it "fails for missing operators" do
        tokens = [
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "x", label: "x", type: :variable, value: "x"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Missing operator before 'x'"])
      end

      it "fails for operators before parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class::Tokenizer.detokenize(tokens)
        expect(result.warnings).to eq(["Operator before ')' is invalid"])
      end
    end
  end
end
