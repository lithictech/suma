# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::PayoutTransaction::OffPlatformStrategy", :db do
  let(:described_class) { Suma::Payment::PayoutTransaction::OffPlatformStrategy }

  let(:strategy) { described_class.create(created_by: Suma::Fixtures.member.create, note: "") }
  let!(:xaction) { Suma::Fixtures.payout_transaction(strategy:).create }

  it_behaves_like "a payout transaction payment strategy"

  it "returns true for all state machine methods" do
    expect(strategy).to be_ready_to_send_funds
    expect(strategy.send_funds).to eq(true)
    expect(strategy).to be_funds_settled
  end
end
