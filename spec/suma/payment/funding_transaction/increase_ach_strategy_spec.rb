# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::FundingTransaction::IncreaseAchStrategy", :db do
  let(:described_class) { Suma::Payment::FundingTransaction::IncreaseAchStrategy }

  let(:bank_account) { Suma::Fixtures.bank_account.verified.create }
  let(:strategy) { described_class.create(originating_bank_account: bank_account) }
  let!(:xaction) { Suma::Fixtures.funding_transaction(strategy:).create }

  it_behaves_like "a funding transaction payment strategy"
  it_behaves_like "a payment strategy with a deletable instrument" do
    def delete_instrument
      bank_account.soft_delete
    end
  end
  it_behaves_like "a payment strategy with a verifiable instrument" do
    def unverify_instrument
      bank_account.update(verified_at: nil)
    end
  end

  describe "ready_to_collect_funds?" do
    it "returns true" do
      expect(strategy).to be_ready_to_collect_funds
    end
  end

  describe "collect_funds" do
    it "creates an Increase ach transfer from the originating bank account to the platform bank account" do
      xaction.update(amount_cents: 2000, memo: "foobar")
      req = stub_request(:post, "https://sandbox.increase.com/transfers/achs").
        with(
          body: hash_including(
            account_id: "sandbox_account_id",
            account_number: bank_account.account_number,
            routing_number: bank_account.routing_number,
            amount: -2000,
            statement_descriptor: "foobar",
          ),
        ).
        to_return(
          status: 200,
          body: {id: "ach-transfer-id"}.to_json,
          headers: {"Content-Type" => "application/json"},
        )
      expect(strategy.collect_funds).to eq(true)
      expect(req).to have_been_made
      expect(strategy.ach_transfer_id).to eq("ach-transfer-id")
    end

    it "noops if an increase ach transfer id is present" do
      strategy.ach_transfer_json = {id: "ach-transfer-id"}.to_json
      expect(strategy.collect_funds).to eq(false)
    end

    it "errors if no Increase ach transfer id is set after it is called" do
      req = stub_request(:post, "https://sandbox.increase.com/transfers/achs").
        to_return(
          status: 200,
          body: {}.to_json,
          headers: {"Content-Type" => "application/json"},
        )
      expect { strategy.collect_funds }.to raise_error(/Increase ACH Transfer Id was not set/)
      expect(req).to have_been_made
    end
  end

  describe "funds_cleared?" do
    it "returns false as per https://github.com/lithictech/suma/issues/79" do
      expect(strategy.funds_cleared?).to eq(false)
    end
  end

  describe "external_links" do
    it "generates external links" do
      expect(strategy.external_links).to eq([])
      strategy.ach_transfer_json = {
        "id" => "xfer",
        "path" => "/transfers/xfer",
        "transaction_id" => "fff",
      }
      expect(strategy.external_links).to eq(
        [
          {name: "ACH Transfer into Increase Account", url: "https://dashboard.increase.com/transfers/xfer"},
          {name: "Transaction for ACH Transfer", url: "https://dashboard.increase.com/transactions/fff"},
        ],
      )
    end
  end
end
