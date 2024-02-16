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

  describe "find_ideal_cash_contribution" do
    let(:ctx) { Suma::Payment::CalculationContext.new(Time.now) }
    let(:account) { Suma::Fixtures.payment_account.create }
    let(:ledger_fac) { Suma::Fixtures.ledger(account:) }
    let!(:cash_ledger) { ledger_fac.category(:cash).create(name: "Dolla") }
    let(:food) { Suma::Fixtures.vendor_service_category.create(name: "food") }
    let(:organic_food) { Suma::Fixtures.vendor_service_category.create(name: "organic", parent: food) }
    let(:organic_food_service) { Suma::Fixtures.vendor_service.with_categories(organic_food).create }
    let(:subsidizing_food_ledger) { Suma::Fixtures.ledger.with_categories(food).create }

    it "errors if the cash ledger has a nonzero balance" do
      Suma::Fixtures.book_transaction.to(cash_ledger).create
      expect do
        described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$5"))
      end.to raise_error(Suma::InvalidPrecondition, /nonzero cash balances/)
    end

    it "uses no cash charge when noncash ledgers can already cover the full amount" do
      organic_food_ledger = ledger_fac.with_categories(organic_food).create
      Suma::Fixtures.book_transaction.to(organic_food_ledger).create(amount: money("$10"))
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$5"))
      expect(got.cash).to have_attributes(amount: be_zero)
      expect(got.remainder).to have_attributes(amount: be_zero)
      expect(got.rest).to contain_exactly(
        have_attributes(amount: cost("$5"), ledger: be === organic_food_ledger),
      )
    end

    it "uses all zero amounts when the charge amount is $0" do
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$0"))
      expect(got.cash).to have_attributes(amount: be_zero)
      expect(got.remainder).to have_attributes(amount: be_zero)
      expect(got.rest).to be_empty
    end

    it "uses the full amount from cash when there are no triggers" do
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$10"))
      expect(got.cash).to have_attributes(amount: cost("$10"))
      expect(got.remainder).to have_attributes(amount: be_zero)
      expect(got.rest).to be_empty
    end

    describe "with payment triggers" do
      it "handles the correct amount at the first bisect step" do
        t = Suma::Fixtures.payment_trigger.matching.from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$10"))
        expect(got.cash).to have_attributes(amount: cost("$5"))
        expect(got.remainder).to have_attributes(amount: be_zero)
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$5")))
      end

      it "handles the correct amount some steps below the first bisect step" do
        t = Suma::Fixtures.payment_trigger.matching(3.8).from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$24"))
        expect(got.cash).to have_attributes(amount: cost("$5"))
        expect(got.remainder).to have_attributes(amount: be_zero)
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$19")))
      end

      it "handles the correct amount some steps above the first bisect step" do
        t = Suma::Fixtures.payment_trigger.matching(0.25).from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$25"))
        expect(got.cash).to have_attributes(amount: cost("$20"))
        expect(got.remainder).to have_attributes(amount: be_zero)
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$5")))
      end

      it "can find inexact amounts" do
        t = Suma::Fixtures.payment_trigger.matching((1 / 3.0).to_f).from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$10.17"))
        expect(got.cash).to have_attributes(amount: cost("$7.63"))
        expect(got.remainder).to have_attributes(amount: be_zero)
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$2.54")))
      end
    end
  end
end
