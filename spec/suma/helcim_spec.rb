# frozen_string_literal: true

require "suma/helcim"

RSpec.describe Suma::Helcim, :db do
  before(:each) do
    described_class.reset_configuration
  end

  describe "request" do
    it "calls the configured endpoint and parses the result" do
      described_class.testmode = false
      req = stub_request(:post, "https://secure.myhelcim.com/api/x").
        with(
          body: "x=1",
          headers: {
            "Accept" => "application/xml",
            "Account-Id" => "helcim_sandbox_account_id",
            "Api-Token" => "test_helcim_key",
            "Content-Type" => "application/x-www-form-urlencoded",
          },
        ).
        to_return(**fixture_response("helcim/preauthorize.xml", format: :xml))

      resp = described_class.make_request("/api/x", {x: 1}, "transaction")
      expect(req).to have_been_made
      expect(resp).to include("transactionId" => "2806832")
    end

    it "errors for a 4xx" do
      req = stub_request(:post, "https://secure.myhelcim.com/api/x").
        to_return(**fixture_response("helcim/error.xml", status: 400, format: :xml))

      expect do
        described_class.make_request("/api/x", {}, "unused")
      end.to raise_error(Suma::Http::Error)
      expect(req).to have_been_made
    end

    it "errors for a response code 0" do
      req = stub_request(:post, "https://secure.myhelcim.com/api/x").
        to_return(**fixture_response("helcim/error.xml", format: :xml))

      expect do
        described_class.make_request("/api/x", {}, "transaction")
      end.to raise_error(described_class::Error, "Error Message Goes Here")
      expect(req).to have_been_made
    end

    it "includes test if in test mode" do
      described_class.testmode = true
      req = stub_request(:post, "https://secure.myhelcim.com/api/x").
        with(body: {"test" => "1", "x" => "1"}).
        to_return(**fixture_response("helcim/preauthorize.xml", format: :xml))

      resp = described_class.make_request("/api/x", {x: 1}, "transaction")
      expect(req).to have_been_made
      expect(resp).to include("transactionId" => "2806832")
    end
  end

  describe "preauthorize" do
    it "calls preauthorize" do
      req = stub_request(:post, "https://secure.myhelcim.com/api/card/pre-authorization").
        with(
          body: {
            "amount" => "2.5",
            "cardF4L4Skip" => "1",
            "cardToken" => "tok123",
            "ecommerce" => "0",
            "ipAddress" => "1.1.1.1",
            "test" => "1",
          },
        ).
        to_return(**fixture_response("helcim/preauthorize.xml", format: :xml))
      resp = described_class.preauthorize(amount: Money.new(250), token: "tok123", ip: "1.1.1.1")
      expect(req).to have_been_made
      expect(resp).to include("transactionId" => "2806832")
    end
  end

  describe "capture" do
    it "calls capture" do
      req = stub_request(:post, "https://secure.myhelcim.com/api/card/capture").
        with(body: {"amount" => "", "test" => "1", "transactionId" => "x123"}).
        to_return(**fixture_response("helcim/capture.xml", format: :xml))
      resp = described_class.capture(transaction_id: "x123")
      expect(req).to have_been_made
      expect(resp).to include("transactionId" => "123076")
    end

    it "can override the amount" do
      req = stub_request(:post, "https://secure.myhelcim.com/api/card/capture").
        with(body: {"amount" => "0.12", "test" => "1", "transactionId" => "x123"}).
        to_return(**fixture_response("helcim/capture.xml", format: :xml))
      resp = described_class.capture(transaction_id: "x123", amount: Money.new(12))
      expect(req).to have_been_made
      expect(resp).to include("transactionId" => "123076")
    end
  end
end
