# frozen_string_literal: true

require "suma/payment/platform_status"

RSpec.describe Suma::Payment::PlatformStatus, :db do
  it "can be calculated" do
    Suma::Fixtures.book_transaction.from(Suma::Fixtures.ledger.platform.create).create
    Suma::Fixtures.funding_transaction.with_fake_strategy.create(amount: money("$5"))
    Suma::Fixtures.payout_transaction.with_fake_strategy.create
    ps = described_class.new.calculate
    expect(ps).to have_attributes(funding: cost("$5"), funding_count: 1)
  end

  it "can be calculated for an empty db" do
    ps = described_class.new.calculate
    expect(ps).to have_attributes(funding: cost("$0"), funding_count: 0)
  end

  it "correctly selects funding and payout transactions (join does not stomp)" do
    f1 = Suma::Fixtures.funding_transaction.with_fake_strategy.create
    f2 = Suma::Fixtures.funding_transaction.create(strategy: Suma::Fixtures.off_platform_payment_strategy.create)
    ps = described_class.new.calculate
    expect(ps).to have_attributes(off_platform_funding_transactions: contain_exactly(have_attributes(id: f2.id)))
  end
end
