# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy", :db do
  let(:described_class) { Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy }

  let(:stripe_charge_id) { "ch_1" }
  let(:strategy) { xaction.strategy }
  let(:xaction) { Suma::Fixtures.payout_transaction(strategy: described_class.create(stripe_charge_id:)).create }

  it_behaves_like "a payout transaction payment strategy"

  describe "ready_to_send_funds?" do
    it "returns true" do
      expect(strategy).to be_ready_to_send_funds
    end
  end

  describe "send_funds" do
    it "creates a refund in Stripe if no refund is set" do
      req = stub_request(:post, "https://api.stripe.com/v1/refunds").
        with(body: hash_including("charge" => "ch_1", amount: xaction.amount.cents.to_s)).
        to_return(json_response(load_fixture_data("stripe/refund")))

      expect(strategy.send_funds).to eq(true)
      expect(req).to have_been_made
      expect(strategy).to have_attributes(
        stripe_charge_id: "ch_1",
        refund_id: "re_1Nispe2eZvKYlo2Cd31jOCgZ",
      )
    end

    it "raises if a not-succeeded refund is set" do
      strategy.refund_json = {"id" => "re_abc", "status" => "pending"}.to_json
      expect { strategy.send_funds }.to raise_error(described_class::WorkInProgressImplementation)
    end

    it "noops if a succeeded refund is present" do
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

  describe "backfill_payouts_from_webhookdb" do
    let(:funding_strategy) do
      Suma::Payment::FundingTransaction::StripeCardStrategy.create(
        originating_card: Suma::Fixtures.card.create,
        charge_json: {id: stripe_charge_id}.to_json,
      )
    end
    let!(:funding_xaction) do
      Suma::Fixtures.funding_transaction(strategy: funding_strategy, amount: Money.new(500)).create
    end
    before(:each) do
      Suma::Webhookdb.stripe_refunds_dataset.insert(
        stripe_id: "re_abc",
        amount: 250,
        charge: stripe_charge_id,
        created: 2.hours.ago,
        status: "succeeded",
        data: {id: "re_abc", status: "succeeded"}.to_json,
      )
    end

    it "creates non-credit refund payout transactions for Stripe refunds in webhookdb" do
      described_class.backfill_payouts_from_webhookdb
      expect(Suma::Payment::PayoutTransaction.all).to contain_exactly(
        have_attributes(
          status: "settled",
          amount: cost("$2.50"),
          originating_payment_account: be === funding_xaction.originating_payment_account,
          originated_book_transaction: be_present,
          crediting_book_transaction: nil,
        ),
      )
      expect(described_class.all).to contain_exactly(
        have_attributes(
          stripe_charge_id:,
          refund_json: hash_including("id" => "re_abc"),
        ),
      )
    end

    it "creates crediting refund payout transactions if the funding transaction is used in a charge" do
      charge = Suma::Fixtures.charge.create
      charge.add_associated_funding_transaction(funding_xaction)
      described_class.backfill_payouts_from_webhookdb
      expect(Suma::Payment::PayoutTransaction.all).to contain_exactly(
        have_attributes(
          status: "settled",
          amount: cost("$2.50"),
          originating_payment_account: be === funding_xaction.originating_payment_account,
          originated_book_transaction: be_present,
          crediting_book_transaction: be_present,
        ),
      )
      expect(described_class.all).to contain_exactly(
        have_attributes(
          stripe_charge_id:,
          refund_json: hash_including("id" => "re_abc"),
        ),
      )
    end

    it "uses recently created strategies to indicate how far back to process refunds" do
      # Create a row so recent that the webhookdb row isn't found
      recent = described_class.create(refund_json: "{}", stripe_charge_id: "ch_2")
      described_class.backfill_payouts_from_webhookdb
      expect(described_class.all).to contain_exactly(be === recent)
    end

    it "does not create multiple strategy rows for the same stripe refund" do
      described_class.backfill_payouts_from_webhookdb
      # Bypass the recency check in the previous test
      described_class.first.this.update(created_at: 5.hours.ago)
      described_class.backfill_payouts_from_webhookdb
      expect(described_class.all).to have_length(1)
      expect(Suma::Payment::PayoutTransaction.all).to have_length(1)
    end

    it "does not create multiple payouts for the same stripe refund" do
      described_class.backfill_payouts_from_webhookdb
      # Try to process the same refund again
      described_class.first.this.update(created_at: 5.hours.ago)
      described_class.backfill_payouts_from_webhookdb
      expect(described_class.all).to have_length(1)
      expect(Suma::Payment::PayoutTransaction.all).to have_length(1)
    end

    it "skips refunds that do not have charges corresponding to a funding transaction charge" do
      funding_strategy.update(charge_json: {id: "ch_other"}.to_json)
      described_class.backfill_payouts_from_webhookdb
      expect(Suma::Payment::PayoutTransaction.all).to be_empty
      expect(described_class.all).to be_empty
    end

    it "only processes successful refunds" do
      Suma::Webhookdb.stripe_refunds_dataset.update(status: "pending")
      described_class.backfill_payouts_from_webhookdb
      expect(Suma::Payment::PayoutTransaction.all).to be_empty
      expect(described_class.all).to be_empty
    end
  end
end
