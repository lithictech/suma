# frozen_string_literal: true

RSpec.describe "Suma::Payment::FakeStrategy", :db do
  let(:described_class) { Suma::Payment::FakeStrategy }

  it "has associations to payouts and funding transactions" do
    ps = Suma::Fixtures.payout_transaction.with_fake_strategy.create
    expect(ps.strategy).to be_a(described_class)
    expect(ps.strategy.payout_transaction).to be === ps

    fs = Suma::Fixtures.funding_transaction.with_fake_strategy.create
    expect(fs.strategy).to be_a(described_class)
    expect(fs.strategy.funding_transaction).to be === fs
  end
end
