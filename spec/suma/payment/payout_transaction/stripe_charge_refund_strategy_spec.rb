# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy", :db do
  let(:described_class) { Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy }

  let(:stripe_charge_id) { "ch_1" }
  let(:strategy) { described_class.create(stripe_charge_id:) }
  let!(:xaction) { Suma::Fixtures.payout_transaction(strategy:).create }

  it_behaves_like "a payout transaction payment strategy"

  describe "ready_to_send_funds?" do
    it "returns true" do
      expect(strategy).to be_ready_to_send_funds
    end
  end

  describe "send_funds" do
    it "raises if no refund is set" do
      expect { strategy.send_funds }.to raise_error(described_class::WorkInProgressImplementation)
    end

    it "raises if a not-succeeded refund is set" do
      strategy.refund_json = {"id" => "re_abc"}.to_json
      expect { strategy.send_funds }.to raise_error(described_class::WorkInProgressImplementation)
    end

    it "noops if a refund is present" do
      strategy.refund_json = {"id" => "re_abc", "status" => "succeeded"}.to_json
      expect(strategy.send_funds).to eq(false)
    end
  end

  describe "funds_settled?" do
    it "is true if the charge is captured" do
      strategy.refund_json = {"id" => "re_123", "status" => "pending"}
      expect(strategy).to_not be_funds_settled

      strategy.refund_json = {"id" => "re_123", "status" => "succeeded"}
      expect(strategy).to be_funds_settled
    end
  end

  describe "external_links" do
    it "generates external links" do
      expect(strategy.external_links).to contain_exactly(include(name: "Stripe Charge"))
      strategy.refund_json = {"id" => "re_abc"}
      expect(strategy.external_links).to contain_exactly(
        {name: "Stripe Charge", url: "https://dashboard.stripe.com/payments/ch_1"},
      )
    end
  end
end
