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
            right: {
              left: {attr: 6, name: "B", fqn: "B"},
              op: "NOT",
            },
          },
          op: "OR",
        },
      }
      tokens = described_class.tokenize(ser)
      expect(tokens.map(&:value).join(" ")).to eq("A.B AND ( ( A.B AND ( NOT B ) ) OR )")
      expect(tokens.map(&:to_h)).to match_array(
        [
          {id: 5, label: "A", type: :variable, value: "A.B"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "(", label: "(", type: :paren, value: "("},
          {id: 5, label: "A", type: :variable, value: "A.B"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "NOT", label: "NOT", type: :operator, value: "NOT"},
          {id: 6, label: "B", type: :variable, value: "B"},
          {id: ")", label: ")", type: :paren, value: ")"},
          {id: ")", label: ")", type: :paren, value: ")"},
          {id: "OR", label: "OR", type: :operator, value: "OR"},
          {id: ")", label: ")", type: :paren, value: ")"},
        ],
      )
    end
  end

  describe "detokenize" do
    def arr2tok(*args)
      return args.map { |t| described_class::Token.new(**t) }
    end

    it "can parse tokens as a serialized expression" do
      tokens = arr2tok(
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
      )
      result = described_class.detokenize(tokens)
      expect(result.node.to_h).to eq(
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

    it "detokenizes empty tokens" do
      result = described_class.detokenize([])
      expect(result.node.to_h).to eq({})
    end

    it "handles single attribute tokens" do
      tokens = arr2tok(
        {id: 5, label: "A", type: :variable, value: "A.B"},
      )
      result = described_class.detokenize(tokens)
      expect(result.node.to_h).to eq({attr: 5, fqn: "A.B", name: "A"})
    end

    it "handles unary operators" do
      tokens = arr2tok(
        {id: "NOT", label: "NOT", type: :operator, value: "NOT"},
        {id: 5, label: "A", type: :variable, value: "A.B"},
      )
      result = described_class.detokenize(tokens)
      expect(result.node.to_h).to eq(
        {
          left: {attr: 5, fqn: "A.B", name: "A"},
          op: "NOT",
        },
      )
    end

    it "handles non-parenthesized expressions" do
      tokens = arr2tok(
        {id: 5, label: "A", type: :variable, value: "A"},
        {id: "AND", label: "AND", type: :operator, value: "AND"},
        {id: "NOT", label: "NOT", type: :operator, value: "NOT"},
        {id: 6, label: "B", type: :variable, value: "B"},
        {id: "OR", label: "OR", type: :operator, value: "OR"},
        {id: "NOT", label: "NOT", type: :operator, value: "NOT"},
        {id: "NOT", label: "NOT", type: :operator, value: "NOT"},
        {id: 7, label: "C", type: :variable, value: "C"},
      )
      result = described_class.detokenize(tokens)
      expect(result.node.to_h).to eq(
        {
          left: {
            left: {attr: 5, fqn: "A", name: "A"},
            op: "AND",
            right: {
              left: {attr: 6, fqn: "B", name: "B"},
              op: "NOT",
            },
          },
          op: "OR",
          right: {
            left: {
              left: {attr: 7, fqn: "C", name: "C"},
              op: "NOT",
            },
            op: "NOT",
          },
        },
      )
    end

    describe "validity" do
      it "fails for invalid types" do
        tokens = arr2tok(
          {id: "AND", label: "AND", type: :foo, value: "AND"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("invalid type: (0) foo")
      end

      it "fails for missing close parens" do
        tokens = arr2tok(
          {id: "(", label: "(", type: :paren, value: "("},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("unexpected end of input: (0) (")
      end

      it "fails for missing open parens" do
        tokens = arr2tok(
          {id: ")", label: ")", type: :paren, value: ")"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("unexpected ): (0)")
      end

      it "fails for empty parens" do
        tokens = arr2tok(
          {id: "(", label: "(", type: :paren, value: "("},
          {id: ")", label: ")", type: :paren, value: ")"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("unexpected ): (1)")
      end

      it "fails for invalid paren values" do
        tokens = arr2tok(
          {id: "x", label: "(", type: :paren, value: "("},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("invalid parenthesis id: (0) x")

        tokens = arr2tok(
          {id: "x", label: ")", type: :paren, value: ")"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("invalid parenthesis id: (0) x")
      end

      it "fails for invalid operators" do
        tokens = arr2tok(
          {id: "x", label: "AND", type: :operator, value: "AND"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("not a unary operator: (0) x")

        tokens = arr2tok(
          {id: 5, label: "A", type: :variable, value: "A.B"},
          {id: "x", label: "AND", type: :operator, value: "AND"},
          {id: 5, label: "A", type: :variable, value: "A.B"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("not a binary operator: (1) x")
      end

      it "fails for misplaced operators" do
        tokens = arr2tok(
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: 5, label: "A", type: :variable, value: "A.B"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("not a unary operator: (0) AND")
      end

      it "fails for closing operators" do
        tokens = arr2tok(
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("unexpected end of input: (1) AND")
      end

      it "fails for missing operators" do
        tokens = arr2tok(
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "x", label: "x", type: :variable, value: "x"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("unexpected token: (1) x")
      end

      it "fails for operators before parens" do
        tokens = arr2tok(
          {id: "(", label: "(", type: :paren, value: "("},
          {id: "x", label: "x", type: :variable, value: "x"},
          {id: "AND", label: "AND", type: :operator, value: "AND"},
          {id: ")", label: ")", type: :paren, value: ")"},
        )
        result = described_class.detokenize(tokens)
        expect(result.error_message).to eq("unexpected ): (3)")
      end
    end
  end
end
