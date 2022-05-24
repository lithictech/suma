# frozen_string_literal: true

require "suma/increase"

RSpec.describe Suma::Increase, :db do
  describe "create_ach_route" do
    it "creates an ach route in Increase" do
      req = stub_request(:post, "https://sandbox.increase.com/accounts/sandbox_account_id/routes/achs").
        with(
          headers: {"Authorization" => "Bearer test_increase_key"},
          body: {name: "testRoute"}.to_json,
        ).
        to_return(
          **fixture_response(body: {
            id: "sandbox_ach_route_123",
            name: "testRoute",
            status: "active",
            account_number: "5561721281",
            routing_number: "053112929",
            account_id: "sandbox_account_id",
          }.to_json),
        )

      resp = described_class.create_ach_route("testRoute")
      expect(req).to have_been_made
      expect(resp).to include("id" => "sandbox_ach_route_123")
    end
  end

  describe "_create_ach_transfer" do
    it "creates an ach transfer in Increase" do
      req = stub_request(:post, "https://sandbox.increase.com/transfers/achs").
        with(
          headers: {"Authorization" => "Bearer test_increase_key"},
          body: {
            account_id: "sandbox_account_id",
            account_number: "acctNum-123",
            amount: 100,
            routing_number: "routNum-456",
            statement_descriptor: "Statement descriptor",
          }.to_json,
        ).
        to_return(
          **fixture_response(body:
            {
              id: "ach_transfer_uoxatyh3lt5evrsdvo7q",
              account_number: "acctNum-123",
              routing_number: "routNum-456",
              account_id: "sandbox_account_id",
              amount: 100,
              status: "submitted",
              statement_descriptor: "Statement descriptor",
              transaction_id: "transaction_uyrp7fld2ium70oa7oi",
            }.to_json),
        )

      resp = described_class._create_ach_transfer(
        account_number: "acctNum-123",
        routing_number: "routNum-456",
        amount_cents: 100,
        memo: "Statement descriptor",
      )
      expect(req).to have_been_made
      expect(resp).to include("id" => "ach_transfer_uoxatyh3lt5evrsdvo7q")
    end
  end

  describe "create_ach_credit_to_bank_account" do
    it "creates a ach transfer in Increase, crediting to the provided bank account" do
      req = stub_request(:post, "https://sandbox.increase.com/transfers/achs").
        with(
          headers: {"Authorization" => "Bearer test_increase_key"},
          body: {
            account_id: "sandbox_account_id",
            account_number: "acctNum-123",
            amount: 100,
            routing_number: "routNum-456",
            statement_descriptor: "Statement descriptor",
          }.to_json,
        ).
        to_return(
          **fixture_response(
            body: {
              id: "ach_transfer_uoxatyh3lt5evrsdvo7q",
              account_number: "acctNum-123",
              routing_number: "routNum-456",
              account_id: "sandbox_account_id",
              amount: 100,
              status: "submitted",
              statement_descriptor: "Statement descriptor",
              transaction_id: "transaction_uyrp7fld2ium70oa7oi",
            }.to_json,
          ),
        )

      bank_account = Suma::Fixtures.bank_account.create(
        account_number: "acctNum-123",
        routing_number: "routNum-456",
      )

      resp = described_class.create_ach_credit_to_bank_account(
        bank_account,
        amount_cents: 100,
        memo: "Statement descriptor",
      )
      expect(req).to have_been_made
      expect(resp).to include("id" => "ach_transfer_uoxatyh3lt5evrsdvo7q")
    end
  end

  describe "create_ach_debit_from_bank_account" do
    it "creates a ach transfer in Increase, debiting from the provided bank account" do
      req = stub_request(:post, "https://sandbox.increase.com/transfers/achs").
        with(
          headers: {"Authorization" => "Bearer test_increase_key"},
          body: {
            account_id: "sandbox_account_id",
            account_number: "acctNum-123",
            amount: -100,
            routing_number: "routNum-456",
            statement_descriptor: "Statement descriptor",
          }.to_json,
        ).to_return(
          **fixture_response(
            body: {
              id: "ach_transfer_uoxatyh3lt5evrsdvo7q",
              account_number: "acctNum-123",
              routing_number: "routNum-456",
              account_id: "sandbox_account_id",
              amount: -100,
              status: "submitted",
              statement_descriptor: "Statement descriptor",
              transaction_id: "transaction_uyrp7fld2ium70oa7oi",
            }.to_json,
          ),
        )

      bank_account = Suma::Fixtures.bank_account.create(
        account_number: "acctNum-123",
        routing_number: "routNum-456",
      )

      resp = described_class.create_ach_debit_from_bank_account(
        bank_account,
        amount_cents: 100,
        memo: "Statement descriptor",
      )
      expect(req).to have_been_made
      expect(resp).to include("id" => "ach_transfer_uoxatyh3lt5evrsdvo7q")
    end

    it "errors if the amount is negative" do
      bank_account = Suma::Fixtures.bank_account.create(
        account_number: "acctNum-123",
        routing_number: "routNum-456",
      )
      expect do
        described_class.create_ach_debit_from_bank_account(
          bank_account,
          amount_cents: -100,
          memo: "Statement descriptor",
        )
      end.to raise_error(Suma::InvalidPrecondition, /amount_cents cannot be negative/)
    end
  end

  describe "get_ach_transfer" do
    it "returns the ach transfer for the specified id" do
      req = stub_request(:get, "https://sandbox.increase.com/transfers/achs/increase_ach_transfer_id").
        with(headers: {"Authorization" => "Bearer test_increase_key"}).
        to_return(
          **fixture_response(
            body: {
              id: "increase_ach_transfer_id",
              account_number: "acctNum-123",
              routing_number: "routNum-456",
              account_id: "sandbox_account_id",
              amount: 100,
              status: "submitted",
              statement_descriptor: "Statement descriptor",
              transaction_id: "transaction_uyrp7fld2ium70oa7oi",
            }.to_json,
          ),
        )

      resp = described_class.get_ach_transfer("increase_ach_transfer_id")
      expect(req).to have_been_made
      expect(resp).to include("status" => "submitted")
    end
  end

  describe "ach_transfer_failed?" do
    it "returns true if the provided ach_transfer_json's status is not a pending state or submitted" do
      ach_transfer_json = {"status" => "rejected"}
      expect(described_class).to be_ach_transfer_failed(ach_transfer_json)
    end

    it "returns false if the provided ach_transfer_json's status is a pending state or submitted" do
      ach_transfer_json = {"status" => "pending_submission"}
      expect(described_class).to_not be_ach_transfer_failed(ach_transfer_json)
      ach_transfer_json = {"status" => "submitted"}
      expect(described_class).to_not be_ach_transfer_failed(ach_transfer_json)
    end
  end

  describe "ach_transfer_succeeded?" do
    it "returns true if transfer is submitted and " \
       "now is at least 5 business days after the ach_transfer_json's created_at in the customer's timezone" do
      pending = {"created_at" => "2020-12-22T12:00:00Z", "status" => "pending_approval"}
      submitted = pending.merge("status" => "submitted")
      late_enough = Time.parse("2020-12-30T20:00:00Z")
      too_early = Time.parse("2020-12-27T20:00:00Z")
      tz = "America/Los_Angeles"
      expect(described_class).to_not be_ach_transfer_succeeded(submitted, customer_timezone: tz, now: too_early)
      expect(described_class).to_not be_ach_transfer_succeeded(pending, customer_timezone: tz, now: late_enough)
      expect(described_class).to be_ach_transfer_succeeded(submitted, customer_timezone: tz, now: late_enough)
    end
  end
end
