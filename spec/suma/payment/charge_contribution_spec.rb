# frozen_string_literal: true

RSpec.describe Suma::Payment::ChargeContribution, :db do
  it "has defaults" do
    expect(described_class.new).to have_attributes(amount: Money.new(0))
  end

  it "is debitable when there is a ledger and positive amount" do
    c = described_class.new
    expect(c).to_not be_debitable
    c.amount = money(5)
    expect(c).to_not be_debitable
    c.ledger = Suma::Fixtures.ledger.create
    expect(c).to be_debitable
    c.amount = money(0)
    expect(c).to_not be_debitable
  end

  it "can be duplicated" do
    c = described_class.new
    c2 = c.dup
    expect(c.object_id).to_not eq(c2.object_id)
    expect(c2).to have_attributes(
      ledger: be(c.ledger),
      category: be(c.category),
      amount: be(c.amount),
      apply_at: be(c.apply_at),
    )
  end

  describe described_class::Collection do
    let(:cash) { Suma::Fixtures.ledger.create(name: "cash") }
    let(:apply_at) { Time.now }

    it "can create an empty instance" do
      c = described_class.create_empty(cash, apply_at:)
      expect(c).to have_attributes(
        cash: have_attributes(ledger: be === cash),
        remainder: have_attributes(amount: cost("$0")),
        rest: [],
      )
    end

    it "knows if there is a remainder" do
      c = described_class.create_empty(cash, apply_at:)
      expect(c).to_not be_remainder
      c.remainder.amount = money("$1")
      expect(c).to be_remainder
    end

    it "can select debitable contributions" do
      c = described_class.create_empty(cash, apply_at:)
      otherledger = Suma::Fixtures.ledger.create
      c.rest << Suma::Payment::ChargeContribution.new(ledger: otherledger)
      c.remainder.amount = money("$1")
      expect(c.debitable).to be_empty

      c.cash.amount = money("$1")
      expect(c.debitable.to_a).to contain_exactly(have_attributes(ledger: be === cash))
      c.rest[0].amount = money("$1")
      expect(c.debitable.to_a).to contain_exactly(
        have_attributes(ledger: be === cash),
        have_attributes(ledger: be === otherledger),
      )
    end

    describe "consolidate" do
      it "combines multiple collections into one, summing amounts" do
        ledgera, ledgerb, ledgerc = "abc".chars.map { |c| Suma::Fixtures.ledger.create(name: c) }

        contrib1 = described_class.create_empty(cash, apply_at:)
        contrib1.cash.amount = money("$1")
        contrib1.remainder.amount = money("$2")

        contrib2 = described_class.create_empty(cash, apply_at:)
        contrib2.cash.amount = money("$10")
        contrib2.remainder.amount = money("$20")
        contrib2.rest << Suma::Payment::ChargeContribution.new(ledger: ledgera, amount: money("$30"))
        contrib2.rest << Suma::Payment::ChargeContribution.new(ledger: ledgerb, amount: money("$40"))

        contrib3 = described_class.create_empty(cash, apply_at:)
        contrib3.cash.amount = money("$100")
        contrib3.rest << Suma::Payment::ChargeContribution.new(ledger: ledgera, amount: money("$300"))
        contrib3.rest << Suma::Payment::ChargeContribution.new(ledger: ledgerc, amount: money("$500"))

        consolidated = described_class.consolidate([contrib1, contrib2, contrib3])
        expect(consolidated.cash).to have_attributes(ledger: be === cash, amount: cost("$111"))
        expect(consolidated.remainder).to have_attributes(ledger: nil, amount: cost("$22"))
        expect(consolidated.rest).to have_length(3)
        expect(consolidated.rest).to contain_exactly(
          have_attributes(ledger: be === ledgera, amount: cost("$330")),
          have_attributes(ledger: be === ledgerb, amount: cost("$40")),
          have_attributes(ledger: be === ledgerc, amount: cost("$500")),
        )
      end
    end
  end
end
