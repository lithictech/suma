# frozen_string_literal: true

RSpec.describe Suma::Payment::CalculationContext, :db do
  it "can return adjusted and unadjusted ledger balances" do
    l1, l2 = "ab".chars.map { |c| Suma::Fixtures.ledger.create(name: c) }
    ctx = described_class.new(Time.now)
    expect(ctx.balance(l1)).to cost("$0")
    expect(ctx.balance(l2)).to cost("$0")
    ctx = ctx.apply_debits(Suma::Payment::ChargeContribution.new(ledger: l1, amount: money("$5")))
    expect(ctx.balance(l1)).to cost("-$5")
    ctx = ctx.apply_debits(Suma::Payment::ChargeContribution.new(ledger: l1, amount: money("$5")))
    expect(ctx.balance(l1)).to cost("-$10")
    ctx = ctx.apply_debits(amount: money("$5"), ledger: l1)
    expect(ctx.balance(l1)).to cost("-$15")
    expect(ctx.balance(l2)).to cost("$0")
  end

  it "can apply multiple contributions" do
    l1, l2 = "ab".chars.map { |c| Suma::Fixtures.ledger.create(name: c) }
    ctx = described_class.new(Time.now)
    ctx = ctx.apply_debits(
      Suma::Payment::ChargeContribution.new(ledger: l1, amount: money("$5")),
      {amount: money("$6"), ledger: l2},
    )
    expect(ctx.balance(l1)).to cost("-$5")
    expect(ctx.balance(l2)).to cost("-$6")
  end

  it "is immutable" do
    led = Suma::Fixtures.ledger.create
    ctx1 = described_class.new(Time.now)
    ctx2 = ctx1.apply_debits({amount: money("$6"), ledger: led})
    expect(ctx1.balance(led)).to cost("$0")
    expect(ctx2.balance(led)).to cost("-$6")
  end

  it "can apply credits" do
    led = Suma::Fixtures.ledger.create
    ctx = described_class.new(Time.now).apply_credits({amount: money("$6"), ledger: led})
    expect(ctx.balance(led)).to cost("$6")
  end

  it "keeps track of credit and debit adjustments" do
    ledger = Suma::Fixtures.ledger.create
    trigger = Suma::Fixtures.payment_trigger.create
    ctx = described_class.new(Time.now).
      apply_credits({amount: money("$6"), ledger:}).
      apply_debits({amount: money("$10"), ledger:}).
      apply_credits({amount: money("$5"), ledger:, trigger:})
    expect(ctx.balance(ledger)).to cost("$1")
    expect(ctx.adjustments_for(ledger)).to contain_exactly(
      have_attributes(amount: cost("$6"), ledger: be === ledger, type: :credit, trigger: nil),
      have_attributes(amount: cost("$10"), ledger: be === ledger, type: :debit, trigger: nil),
      have_attributes(amount: cost("$5"), ledger: be === ledger, type: :credit, trigger: be === trigger),
    )
    expect(ctx.adjustments_for(Suma::Fixtures.ledger.create)).to eq([])
  end
end
