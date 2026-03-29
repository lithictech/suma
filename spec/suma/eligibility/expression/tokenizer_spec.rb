# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Expression::Tokenizer", :db do
  let(:described_class) { Suma::Eligibility::Expression::Tokenizer }

  describe "Expression tokenize" do
    it "tokenizes no tokens for an empty expression" do
      expr = Suma::Fixtures.eligibility_expression.create
      expect(expr.tokenize).to eq([])
    end
  end

  describe "tokenize" do
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
      tokens = described_class.tokenize(ser)
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
  end

  describe "detokenize" do
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
      ].map { |t| described_class::Token.new(**t) }
      result = described_class.detokenize(tokens)
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
      ].map { |t| described_class::Token.new(**t) }
      result = described_class.detokenize(tokens)
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

    it "detokenizes empty tokens" do
      result = described_class.detokenize([])
      expect(result.warnings.map(&:to_s)).to eq([])
      expect(result.serialized).to eq({})
    end

    it "handles single attribute tokens" do
      tokens = [
        {id: 5, label: "A", type: :variable, value: "A.B"},
      ].map { |t| described_class::Token.new(**t) }
      result = described_class.detokenize(tokens)
      expect(result.warnings.map(&:to_s)).to eq([])
      expect(result.serialized).to eq({attr: 5, fqn: "A.B", name: "A"})
    end

    describe "validity" do
      it "fails for invalid types" do
        tokens = [
          {id: "AND", label: "AND", type: :foo, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["invalid type: (0) foo"])
      end

      it "fails for missing close parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["unmatched opening parenthesis: (0)"])
      end

      it "fails for missing open parens" do
        tokens = [
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["unmatched closing parenthesis: (0)"])
      end

      it "fails for empty parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["empty parentheses are not allowed: (0)"])
      end

      it "fails for invalid paren values" do
        tokens = [
          {id: "x", label: "(", type: :paren, value: "("},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["invalid parenthesis id: (0) x"])
      end

      it "fails for invalid operators" do
        tokens = [
          {id: "x", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["invalid operator id: (0) x"])
      end

      it "fails for misplaced operators" do
        tokens = [
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: 5, label: "A", type: :variable, value: "A.B"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["cannot appear here: (0) AND"])
      end

      it "fails for closing operators" do
        tokens = [
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["expression cannot end with operator: (1) AND"])
      end

      it "fails for missing operators" do
        tokens = [
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "x", label: "x", type: :variable, value: "x"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["operator required before variable: (1) x"])
      end

      it "fails for operators before parens" do
        tokens = [
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: ")", label: ")", type: :paren, value: ")"},
        ].map { |t| described_class::Token.new(**t) }
        result = described_class.detokenize(tokens)
        expect(result.warnings.map(&:to_s)).to eq(["operator before ) is invalid: (3)"])
      end
    end
  end
end
