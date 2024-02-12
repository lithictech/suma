# frozen_string_literal: true

RSpec.describe Suma::Payment::CalculationContext, :db do
  it "can return adjusted and unadjusted ledger balances" do
    l1, l2 = "ab".chars.map { |c| Suma::Fixtures.ledger.create(name: c) }
    ctx = described_class.new
    expect(ctx.balance(l1)).to cost("$0")
    expect(ctx.balance(l2)).to cost("$0")
    ctx.apply(Suma::Payment::ChargeContribution.new(ledger: l1, amount: money("$5")))
    expect(ctx.balance(l1)).to cost("-$5")
    ctx.apply(Suma::Payment::ChargeContribution.new(ledger: l1, amount: money("$5")))
    expect(ctx.balance(l1)).to cost("-$10")
    ctx.apply(amount: money("$5"), ledger: l1)
    expect(ctx.balance(l1)).to cost("-$15")
    expect(ctx.balance(l2)).to cost("$0")
  end

  it "can apply multiple contributions" do
    l1, l2 = "ab".chars.map { |c| Suma::Fixtures.ledger.create(name: c) }
    ctx = described_class.new
    ctx.apply_many(
      Suma::Payment::ChargeContribution.new(ledger: l1, amount: money("$5")),
      {amount: money("$6"), ledger: l2},
    )
    expect(ctx.balance(l1)).to cost("-$5")
    expect(ctx.balance(l2)).to cost("-$6")
  end
end
