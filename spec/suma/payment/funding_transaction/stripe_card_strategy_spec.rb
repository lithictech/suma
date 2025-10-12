# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::FundingTransaction::StripeCardStrategy", :db do
  let(:described_class) { Suma::Payment::FundingTransaction::StripeCardStrategy }

  let(:member) { Suma::Fixtures.member.registered_as_stripe_customer.create }
  let(:card) { Suma::Fixtures.card.member(member).with_stripe({"id" => "card_123"}).create }
  let(:strategy) { described_class.create(originating_card: card) }
  let!(:xaction) { Suma::Fixtures.funding_transaction(strategy:).create }

  it_behaves_like "a funding transaction payment strategy"
  it_behaves_like "a payment strategy with a deletable instrument" do
    def delete_instrument
      card.soft_delete
    end
  end

  describe "check_validity" do
    it "errors if the member is not registered in Stripe" do
      strategy.originating_card.member.stripe_customer_json = nil
      expect(strategy.check_validity).to contain_exactly("member is not registered in Stripe")
    end
  end

  describe "ready_to_collect_funds?" do
    it "returns true" do
      expect(strategy).to be_ready_to_collect_funds
    end
  end

  describe "collect_funds" do
    it "preauthorizes a change" do
      xaction.update(amount_cents: 2000)
      req = stub_request(:post, "https://api.stripe.com/v1/charges").
        with(
          body: hash_including(
            "amount" => "2000",
            "capture" => "false",
            "currency" => "USD",
            "customer" => member.stripe.customer_id,
            "description" => "suma charge",
            "source" => "card_123",
          ),
        ).to_return(**fixture_response("stripe/charge"))

      strategy.collect_funds
      expect(req).to have_been_made
      expect(strategy.charge_id).to eq("ch_1Cgkfs2eZvKYlo2CVPsK4I3f")
    end

    it "noops if a charge is present" do
      strategy.charge_json = {"id" => "ch_abc"}.to_json
      expect { strategy.collect_funds }.to_not(change { strategy.charge_json })
    end
  end

  describe "funds_cleared?" do
    it "captures a present preauth" do
      strategy.charge_json = {"id" => "ch_123"}
      stub_request(:post, "https://api.stripe.com/v1/charges/ch_123/capture").
        to_return(**fixture_response("stripe/charge"))
      expect(strategy).to be_funds_cleared
      expect(strategy).to have_attributes(charge_id: "ch_1Cgkfs2eZvKYlo2CVPsK4I3f")
    end

    it "errors if there is no charge" do
      expect do
        strategy.funds_cleared?
      end.to raise_error(Suma::InvalidPrecondition, /Stripe charge id not set/)
    end

    it "is true if the charge is captured" do
      strategy.charge_json = {"id" => "ch_123", "captured" => true}
      expect(strategy).to be_funds_cleared
    end

    it "re-fetches the charge if Stripe says it has been refunded" do
      strategy.charge_json = {"id" => "ch_123", "captured" => false}

      error_body = load_fixture_data("stripe/charge_error")
      error_body["error"]["code"] = "charge_already_refunded"
      capture_req = stub_request(:post, "https://api.stripe.com/v1/charges/ch_123/capture").
        to_return(fixture_response(body: error_body.to_json, status: 400))

      get_body = load_fixture_data("stripe/charge")
      get_body["status"] = "failed"
      get_body["captured"] = false
      get_req = stub_request(:get, "https://api.stripe.com/v1/charges/ch_123").
        to_return(fixture_response(body: get_body.to_json))

      expect(strategy).to_not be_funds_cleared
      expect(capture_req).to have_been_made
      expect(get_req).to have_been_made
      expect(strategy.charge_json.as_json).to include("status" => "failed")
      expect(strategy).to be_funds_canceled
    end

    it "puts a payment into needs_review if it has expired" do
      strategy.charge_json = {"id" => "ch_123", "captured" => false}

      error_body = load_fixture_data("stripe/charge_error")
      error_body["error"]["code"] = "charge_expired_for_capture"
      capture_req = stub_request(:post, "https://api.stripe.com/v1/charges/ch_123/capture").
        to_return(fixture_response(body: error_body.to_json, status: 400))

      expect(strategy).to_not be_funds_cleared
      expect(capture_req).to have_been_made
      expect(xaction).to be_flagging_for_review
    end

    it "raises for an unhandled Stripe response" do
      strategy.charge_json = {"id" => "ch_123", "captured" => false}

      error_body = load_fixture_data("stripe/charge_error")
      error_body["error"]["code"] = "unhandled_test_error"
      error_body["error"]["message"] = "Test message"
      capture_req = stub_request(:post, "https://api.stripe.com/v1/charges/ch_123/capture").
        to_return(fixture_response(body: error_body.to_json, status: 400))

      expect do
        strategy.funds_cleared?
      end.to raise_error(Stripe::InvalidRequestError, /Test message/)
      expect(capture_req).to have_been_made
    end
  end

  describe "funds_canceled?" do
    it "errors if there is no charge" do
      expect do
        strategy.funds_cleared?
      end.to raise_error(Suma::InvalidPrecondition, /Stripe charge id not set/)
    end

    it "is true if the charge is failed" do
      strategy.charge_json = {"id" => "ch_123", "status" => "failed"}
      expect(strategy).to be_funds_canceled
      strategy.charge_json = {"id" => "ch_123", "status" => "pending"}
      expect(strategy).to_not be_funds_canceled
    end
  end

  describe "external_links" do
    it "generates external links" do
      expect(strategy.external_links).to contain_exactly(have_attributes(name: "Stripe Customer"))
      strategy.charge_json = {"id" => "ch_abc"}
      expect(strategy.external_links).to contain_exactly(
        have_attributes(name: "Stripe Customer"),
        have_attributes(name: "Stripe Charge", url: "https://dashboard.stripe.com/payments/ch_abc"),
      )
    end
  end
end
