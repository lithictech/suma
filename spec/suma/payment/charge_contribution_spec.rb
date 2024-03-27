# frozen_string_literal: true

RSpec.describe Suma::Payment::ChargeContribution, :db do
  it "has defaults" do
    expect(described_class.new).to have_attributes(amount: Money.new(0))
  end

  it "calculates outstanding and from_balance from its balance" do
    ledger = Suma::Fixtures.ledger.create
    c = described_class.new(ledger:)
    expect(c).to have_attributes(
      outstanding: cost("$0"),
      outstanding?: false,
      from_balance: cost("$0"),
      from_balance?: false,
      amount?: false,
    )
    c = c.dup(amount: money("$5"))
    expect(c).to have_attributes(
      outstanding: cost("$5"),
      outstanding?: true,
      from_balance: cost("$0"),
      from_balance?: false,
      amount?: true,
    )

    Suma::Fixtures.book_transaction.to(ledger).create(amount: money("$2"))
    expect(c).to have_attributes(
      outstanding: cost("$3"),
      outstanding?: true,
      from_balance: cost("$2"),
      from_balance?: true,
    )

    Suma::Fixtures.book_transaction.to(ledger).create(amount: money("$4"))
    expect(c).to have_attributes(
      outstanding: cost("$0"),
      outstanding?: false,
      from_balance: cost("$5"),
      from_balance?: true,
    )
  end

  it "does not factor in negative ledger balances to what is oustanding/from_balance" do
    ledger = Suma::Fixtures.ledger.create
    Suma::Fixtures.book_transaction.from(ledger).create(amount: money("$4"))
    c = described_class.new(ledger:)
    expect(c).to have_attributes(
      outstanding: cost("$0"),
      outstanding?: false,
      from_balance: cost("$0"),
      from_balance?: false,
      amount?: false,
    )
    c = c.dup(amount: money("$5"))
    expect(c).to have_attributes(
      outstanding: cost("$5"),
      outstanding?: true,
      from_balance: cost("$0"),
      from_balance?: false,
      amount?: true,
    )
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
    expect(c2.dup(amount: money("$5.12"))).to have_attributes(
      ledger: be(c.ledger),
      amount: money("$5.12"),
      apply_at: be(c.apply_at),
    )
  end

  describe described_class::Collection do
    let(:cash) { Suma::Fixtures.ledger.create(name: "cash") }
    let(:ctx) { Suma::Payment::CalculationContext.new(Time.now) }

    it "can create an empty instance" do
      c = described_class.create_empty(ctx, cash)
      expect(c).to have_attributes(
        cash: have_attributes(ledger: be === cash),
        remainder: cost("$0"),
        rest: [],
      )
    end

    it "knows if there is a remainder" do
      c = described_class.create_empty(ctx, cash)
      expect(c).to_not be_remainder
      c.remainder = money("$1")
      expect(c).to be_remainder
    end

    it "can enumerate contributions" do
      c = described_class.create_empty(ctx, cash)
      otherledger = Suma::Fixtures.ledger.create
      c.rest << Suma::Payment::ChargeContribution.new(ledger: otherledger)

      c.all
      c.all.to_a
      expect(c.all.to_a.map(&:ledger)).to have_same_ids_as(cash, otherledger).ordered
      expect(c.all(cash: :last).to_a.map(&:ledger)).to have_same_ids_as(otherledger, cash).ordered
      cashfirst = []
      c.all { |ch| cashfirst << ch.ledger }
      cashlast = []
      c.all(cash: :last) { |ch| cashlast << ch.ledger }
      expect(cashfirst).to have_same_ids_as(cash, otherledger).ordered
      expect(cashlast).to have_same_ids_as(otherledger, cash).ordered
    end

    describe "consolidate" do
      it "combines multiple collections into one, summing amounts" do
        ledgera, ledgerb, ledgerc = "abc".chars.map { |c| Suma::Fixtures.ledger.create(name: c) }

        contrib1 = described_class.create_empty(ctx, cash)
        contrib1.cash.mutate_amount(money("$1"))
        contrib1.remainder = money("$2")

        contrib2 = described_class.create_empty(ctx, cash)
        contrib2.cash.mutate_amount(money("$10"))
        contrib2.remainder = money("$20")
        contrib2.rest << Suma::Payment::ChargeContribution.new(ledger: ledgera, amount: money("$30"))
        contrib2.rest << Suma::Payment::ChargeContribution.new(ledger: ledgerb, amount: money("$40"))

        contrib3 = described_class.create_empty(ctx, cash)
        contrib3.cash.mutate_amount(money("$100"))
        contrib3.rest << Suma::Payment::ChargeContribution.new(ledger: ledgera, amount: money("$300"))
        contrib3.rest << Suma::Payment::ChargeContribution.new(ledger: ledgerc, amount: money("$500"))

        ctx = Suma::Payment::CalculationContext.new(Time.now)
        consolidated = described_class.consolidate(ctx, [contrib1, contrib2, contrib3])
        expect(consolidated.context).to be(ctx)
        expect(consolidated.cash).to have_attributes(ledger: be === cash, amount: cost("$111"))
        expect(consolidated.remainder).to cost("$22")
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

    it "handles contributions from a cash ledger has a nonzero balance" do
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$3"))
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$5"))
      expect(got.cash).to have_attributes(amount: cost("$5"), outstanding: cost("$2"), from_balance: cost("$3"))
      expect(got.remainder).to cost("$0")
      expect(got.rest).to be_empty
    end

    it "uses no cash charge when noncash ledgers can already cover the full amount" do
      organic_food_ledger = ledger_fac.with_categories(organic_food).create
      Suma::Fixtures.book_transaction.to(organic_food_ledger).create(amount: money("$10"))
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$5"))
      expect(got.cash).to have_attributes(amount: be_zero)
      expect(got.remainder).to cost("$0")
      expect(got.rest).to contain_exactly(
        have_attributes(amount: cost("$5"), ledger: be === organic_food_ledger),
      )
    end

    it "uses all zero amounts when the charge amount is $0" do
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$0"))
      expect(got.cash).to have_attributes(amount: be_zero)
      expect(got.remainder).to cost("$0")
      expect(got.rest).to be_empty
    end

    it "uses the full amount from cash when there are no triggers" do
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$10"))
      expect(got.cash).to have_attributes(amount: cost("$10"))
      expect(got.remainder).to cost("$0")
      expect(got.rest).to be_empty
    end

    it "bisects properly with existing cash and noncash contributions" do
      food_ledger = ledger_fac.with_categories(organic_food).create
      Suma::Fixtures.book_transaction.to(food_ledger).create(amount: money("$3"))
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$0.30"))
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$800"))
      expect(got.cash).to have_attributes(
        amount: cost("$797"),
        from_balance: cost("$0.30"),
        outstanding: cost("$796.70"),
      )
      expect(got.remainder).to cost("$0")
      expect(got.rest).to contain_exactly(have_attributes(amount: cost("$3"), ledger: be === food_ledger))
    end

    it "can be applied multiple times with accumulating contexts" do
      got1 = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$800"))
      expect(got1.cash).to have_attributes(amount: cost("$800"))
      expect(got1.remainder).to cost("$0")
      expect(got1.rest).to be_empty

      ctx2 = ctx.apply_debits(*got1.all)
      got2 = described_class.find_ideal_cash_contribution(ctx2, account, organic_food_service, money("$300"))
      expect(got2.cash).to have_attributes(amount: cost("$300"))
      expect(got2.remainder).to cost("$0")
      expect(got2.rest).to be_empty
    end

    it "can be applied multiple times with acculating contexts, having existing cash and noncash contributions" do
      food_ledger = ledger_fac.with_categories(organic_food).create
      # Start with money on each ledger
      Suma::Fixtures.book_transaction.to(food_ledger).create(amount: money("$30"))
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$40"))

      # $20 food should take all from food ledger
      ctx1 = ctx
      got1 = described_class.find_ideal_cash_contribution(ctx1, account, organic_food_service, money("$20"))
      expect(got1.cash).to have_attributes(amount: cost("0"))
      expect(got1.remainder).to cost("$0")
      expect(got1.rest).to contain_exactly(have_attributes(amount: cost("$20")))

      # $30 food should take remaining $10 from food, and $20 from cash
      ctx2 = ctx1.apply_debits(*got1.all)
      got2 = described_class.find_ideal_cash_contribution(ctx2, account, organic_food_service, money("$30"))
      expect(got2.cash).to have_attributes(amount: cost("$20"))
      expect(got2.remainder).to cost("$0")
      expect(got2.rest).to contain_exactly(have_attributes(amount: cost("$10")))

      # $30 more in food should take remaining $10 from cash, and owe $20 cash
      ctx3 = ctx2.apply_debits(*got2.all)
      got3 = described_class.find_ideal_cash_contribution(ctx3, account, organic_food_service, money("$30"))
      expect(got3.cash).to have_attributes(amount: cost("$30"))
      expect(got3.remainder).to cost("$0")
      expect(got3.rest).to contain_exactly(have_attributes(amount: cost("$0")))
    end

    it "does not require 'paying off' negative ledger balances" do
      food_ledger = ledger_fac.with_categories(organic_food).create
      Suma::Fixtures.book_transaction.from(food_ledger).create(amount: money("$3"))
      Suma::Fixtures.book_transaction.from(cash_ledger).create(amount: money("$0.30"))
      got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$30"))
      expect(got.cash).to have_attributes(
        amount: cost("$30"),
        from_balance: cost("$0"),
        outstanding: cost("$30"),
      )
      expect(got.remainder).to cost("$0")
      expect(got.rest).to contain_exactly(have_attributes(amount: cost("$0"), ledger: be === food_ledger))
    end

    it "raises if a $0 step is calculated" do
      # there's no whole cent value of x for the equation:
      # $3 + $x + ($x * 3.8) = $24
      # See code for more info.
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$3"))
      Suma::Fixtures.payment_trigger.matching(3.8).up_to(money("$19")).from(subsidizing_food_ledger).create
      led = Suma::Fixtures.ledger.with_categories(food).create(account:)
      expect do
        described_class.find_ideal_cash_contribution(ctx, account, led, money("$24"))
      end.to raise_error(described_class::InvalidCalculation, /Got a \$0 step bisecting 24\.00 13 times/)
    end

    describe "with payment triggers" do
      it "handles the correct amount at the first bisect step" do
        t = Suma::Fixtures.payment_trigger.matching.from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$10"))
        expect(got.cash).to have_attributes(amount: cost("$5"))
        expect(got.remainder).to cost("$0")
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$5")))
      end

      it "handles the correct amount some steps below the first bisect step" do
        t = Suma::Fixtures.payment_trigger.matching(3.8).from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$24"))
        expect(got.cash).to have_attributes(amount: cost("$5"))
        expect(got.remainder).to cost("$0")
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$19")))
      end

      it "handles the correct amount some steps above the first bisect step" do
        t = Suma::Fixtures.payment_trigger.matching(0.25).from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$25"))
        expect(got.cash).to have_attributes(amount: cost("$20"))
        expect(got.remainder).to cost("$0")
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$5")))
      end

      it "can find inexact amounts" do
        t = Suma::Fixtures.payment_trigger.matching((1 / 3.0).to_f).from(subsidizing_food_ledger).create
        got = described_class.find_ideal_cash_contribution(ctx, account, organic_food_service, money("$10.17"))
        expect(got.cash).to have_attributes(amount: cost("$7.63"))
        expect(got.remainder).to cost("$0")
        expect(got.rest).to contain_exactly(have_attributes(amount: cost("$2.54")))
      end
    end
  end
end
