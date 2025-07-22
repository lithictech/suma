# frozen_string_literal: true

require_relative "behaviors"

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

  it_behaves_like "a funding transaction payment strategy" do
    let(:strategy) { xaction.strategy }
    let(:xaction) { Suma::Fixtures.funding_transaction.with_fake_strategy.create }

    it "ignores webmock errors" do
      run_error_test { Suma::Http.get("/fakeurl", logger: nil, timeout: nil) }
    end
  end

  it_behaves_like "a payout transaction payment strategy" do
    let(:strategy) { xaction.strategy }
    let(:xaction) { Suma::Fixtures.payout_transaction.with_fake_strategy.create }

    it "ignores webmock errors" do
      run_error_test { Suma::Http.get("/fakeurl", logger: nil, timeout: nil) }
    end
  end
end
