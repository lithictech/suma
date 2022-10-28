# frozen_string_literal: true

require "suma/api/payments"

RSpec.describe Suma::API::Payments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }

  before(:each) do
    login_as(member)
  end

  describe "POST /v1/payments/create_funding" do
    it "creates a new funding and book transaction" do
      ba = Suma::Fixtures.bank_account.member(member).verified.create

      post "/v1/payments/create_funding",
           amount: {cents: 500, currency: "USD"},
           payment_instrument_id: ba.id,
           payment_method_type: ba.payment_method_type

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
      expect(last_response).to have_json_body.that_includes(status: "created")

      expect(member.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(status: "created", originated_book_transaction: be_present),
      )
      expect(member.payment_account.cash_ledger.received_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$5")),
      )
      expect(member.payment_account).to have_attributes(total_balance: cost("$5"))
    end

    it "can use a bank account" do
      ba = Suma::Fixtures.bank_account.member(member).verified.create

      # Travel to a holiday so we don't try to collect funds
      Timecop.travel("2022-10-30T12:00:00Z") do
        post "/v1/payments/create_funding",
             amount: {cents: 500, currency: "USD"},
             payment_instrument_id: ba.id,
             payment_method_type: ba.payment_method_type
      end

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(status: "created")
    end

    it "can use a card" do
      Suma::Fixtures::Members.register_as_stripe_customer(member)
      card = Suma::Fixtures.card.member(member).create
      req = stub_request(:post, "https://api.stripe.com/v1/charges").
        to_return(fixture_response("stripe/charge"))

      post "/v1/payments/create_funding",
           amount: {cents: 500, currency: "USD"},
           payment_instrument_id: card.id,
           payment_method_type: card.payment_method_type

      expect(last_response).to have_status(200)
      expect(req).to have_been_made
      expect(last_response).to have_json_body.that_includes(status: "collecting")
    end

    it "errors if the bank account is not usable" do
      ba = Suma::Fixtures.bank_account.member(member).create
      ba.soft_delete

      post "/v1/payments/create_funding",
           amount: {cents: 500, currency: "USD"},
           payment_instrument_id: ba.id,
           payment_method_type: ba.payment_method_type

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "resource_not_found"))
    end

    it "errors if amount_cents param has invalid minimum" do
      ba = Suma::Fixtures.bank_account.member(member).verified.create

      post "/v1/payments/create_funding",
           amount: {cents: 1, currency: "USD"},
           payment_instrument_id: ba.id,
           payment_method_type: ba.payment_method_type

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(
        errors: ["amount[cents] must be at least 500"], code: "validation_error",
      ))
    end
  end
end
