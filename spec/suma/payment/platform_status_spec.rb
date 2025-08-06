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
end
