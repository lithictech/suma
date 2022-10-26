# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::FundingTransaction::HelcimCardStrategy", :db do
  let(:described_class) { Suma::Payment::FundingTransaction::HelcimCardStrategy }

  let(:card) { Suma::Fixtures.card.with_helcim({"cardToken" => "tok123"}).create }
  let(:strategy) { described_class.create(originating_card: card) }
  let!(:xaction) { Suma::Fixtures.funding_transaction(strategy:, originating_ip: "8.196.255.88").create }

  it_behaves_like "a funding transaction payment strategy"
  it_behaves_like "a payment strategy with a deletable instrument" do
    def delete_instrument
      card.soft_delete
    end
  end

  describe "check_validity" do
    it "errors if funding transaction does not have a member ip" do
      strategy.funding_transaction.originating_ip = nil
      expect(strategy.check_validity).to contain_exactly("requires the originating ip to be set")
    end
  end

  describe "ready_to_collect_funds?" do
    it "returns true" do
      expect(strategy).to be_ready_to_collect_funds
    end
  end

  describe "collect_funds" do
    it "creates a Helcim preauth" do
      xaction.update(amount_cents: 2000)
      req = stub_request(:post, "https://secure.myhelcim.com/api/card/pre-authorization").
        with(
          body: {
            "amount" => "20.0",
            "cardF4L4Skip" => "1",
            "cardToken" => "tok123",
            "ecommerce" => "0",
            "ipAddress" => "8.196.255.88",
            "test" => "1",
          },
        ).to_return(**fixture_response("helcim/preauthorize.xml", format: :xml))

      expect(strategy.collect_funds).to eq(true)
      expect(req).to have_been_made
      expect(strategy.transaction_id).to eq("2806832")
    end

    it "noops if a helcim preauth is present" do
      strategy.preauth_json = {transactionId: "abc"}.to_json
      expect(strategy.collect_funds).to eq(false)
    end

    it "noops if a helcim capture (but not preauth) is present" do
      strategy.capture_json = {transactionId: "abc"}.to_json
      expect(strategy.collect_funds).to eq(false)
    end

    it "errors if no transaction id is set after being created" do
      xaction.update(amount_cents: 2000)
      req = stub_request(:post, "https://secure.myhelcim.com/api/card/pre-authorization").
        to_return(**fixture_response(body: "<message><response>1</response><transaction /></message>", format: :xml))

      expect do
        strategy.collect_funds
      end.to raise_error(Suma::InvalidPostcondition, /Helcim preauth transaction id/)
      expect(req).to have_been_made
    end
  end

  describe "funds_cleared?" do
    it "captures a present preauth" do
      strategy.preauth_json = {"transactionId" => "123"}
      stub_request(:post, "https://secure.myhelcim.com/api/card/capture").
        with(body: {"amount" => "", "test" => "1", "transactionId" => "123"}).
        to_return(**fixture_response("helcim/capture.xml", format: :xml))
      expect(strategy).to be_funds_cleared
      expect(strategy).to have_attributes(capture_transaction_id: "123076")
    end

    it "errors if there is no preauth or capture json" do
      expect do
        strategy.funds_cleared?
      end.to raise_error(Suma::InvalidPrecondition, /preauth transaction id/)
    end

    it "is true if there is capture json set" do
      strategy.capture_json = {"transactionId" => "123"}
      expect(strategy).to be_funds_cleared
    end
  end

  describe "external_links" do
    it "generates external links" do
      # expect(strategy.external_links).to eq([])
      # strategy.ach_transfer_json = {
      #   "id" => "xfer",
      #   "path" => "/transfers/xfer",
      #   "transaction_id" => "fff",
      # }
      # expect(strategy.external_links).to eq(
      #   [
      #     {name: "ACH Transfer into Increase Account", url: "https://dashboard.increase.com/transfers/xfer"},
      #     {name: "Transaction for ACH Transfer", url: "https://dashboard.increase.com/transactions/fff"},
      #   ],
      # )
    end
  end
end
