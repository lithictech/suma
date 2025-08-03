# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::FundingTransaction::OffPlatformStrategy", :db do
  let(:described_class) { Suma::Payment::FundingTransaction::OffPlatformStrategy }

  let(:strategy) { described_class.create(created_by: Suma::Fixtures.member.create, note: "") }
  let!(:xaction) { Suma::Fixtures.funding_transaction(strategy:).create }

  it_behaves_like "a funding transaction payment strategy"

  it "returns true for all state machine methods" do
    expect(strategy).to be_ready_to_collect_funds
    expect(strategy.collect_funds).to eq(true)
    expect(strategy).to be_funds_cleared
    expect(strategy).to_not be_funds_canceled
  end
end
