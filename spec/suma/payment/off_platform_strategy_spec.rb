# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::OffPlatformStrategy", :db do
  let(:described_class) { Suma::Payment::OffPlatformStrategy }

  describe "as a funding strategy" do
    let(:strategy) do
      described_class.create(transacted_at: Time.now, created_by: Suma::Fixtures.member.create, note: "")
    end
    let!(:xaction) { Suma::Fixtures.funding_transaction(strategy:).create }

    it_behaves_like "a funding transaction payment strategy"

    it "returns true for all state machine methods" do
      expect(strategy).to be_ready_to_collect_funds
      expect(strategy.collect_funds).to eq(true)
      expect(strategy).to be_funds_cleared
      expect(strategy).to_not be_funds_canceled
    end
  end

  describe "as a payout strategy" do
    let(:strategy) do
      described_class.create(transacted_at: Time.now, created_by: Suma::Fixtures.member.create, note: "")
    end
    let!(:xaction) { Suma::Fixtures.payout_transaction(strategy:).create }

    it_behaves_like "a payout transaction payment strategy"

    it "returns true for all state machine methods" do
      expect(strategy).to be_ready_to_send_funds
      expect(strategy.send_funds).to eq(true)
      expect(strategy).to be_funds_settled
    end
  end
end
