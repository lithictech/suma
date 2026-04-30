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
    it "creates a new funding and book transaction", :i18n do
      ba = Suma::Fixtures.bank_account.member(member).verified.create

      Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
        post "/v1/payments/create_funding",
             amount: {cents: 500, currency: "USD"},
             payment_instrument_id: ba.id,
             payment_method_type: ba.payment_method_type
      end

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
      expect(last_response).to have_json_body.that_includes(status: "created")

      expect(member.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(status: "created"),
      )
    end

    it "can use a bank account", :i18n do
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

    it "can use a card", :i18n do
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

  describe "POST /v1/payments/charge_balance" do
    let(:platform_account) { Suma::Payment::Account.lookup_platform_account }
    let(:platform_cash) { platform_account.ensure_cash_ledger }
    let(:cash) { Suma::Payment.ensure_cash_ledger(member) }

    before(:each) do
      Suma::Fixtures::Members.register_as_stripe_customer(member)
    end

    describe "when there is not a negative cash ledger balance" do
      it "noops" do
        Suma::Fixtures.card.member(member).create

        post "/v1/payments/charge_balance"

        expect(last_response).to have_status(200)
        expect(Suma::Payment::FundingTransaction.all).to be_empty
      end
    end

    describe "when there is a negative cash ledger balance" do
      before(:each) do
        Suma::Fixtures.book_transaction.from(cash).to(platform_cash).create(amount: money("$50"))
      end

      it "runs the ledger balance charger", :i18n do
        Suma::Fixtures.card.member(member).create

        Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.ready) do
          post "/v1/payments/charge_balance"
        end

        expect(last_response).to have_status(200)
        expect(Suma::Payment::FundingTransaction.all).to have_length(1)
      end

      it "errors if no charge is created", :i18n do
        # No instruments, so this should fail

        post "/v1/payments/charge_balance"

        expect(last_response).to have_status(402)
        expect(last_response).to have_json_body.
          that_includes(error: include(code: "charge_balance"))
        expect(Suma::Payment::FundingTransaction.all).to be_empty
      end
    end
  end
end
