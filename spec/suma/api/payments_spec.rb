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
           payment_method_id: ba.id,
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

    it "errors if the bank account is not usable" do
      ba = Suma::Fixtures.bank_account.member(member).create
      ba.soft_delete

      post "/v1/payments/create_funding",
           amount: {cents: 500, currency: "USD"},
           payment_method_id: ba.id,
           payment_method_type: ba.payment_method_type

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "resource_not_found"))
    end

    it "errors if amount_cents param has invalid minimum" do
      ba = Suma::Fixtures.bank_account.member(member).verified.create

      post "/v1/payments/create_funding",
           amount: {cents: 1, currency: "USD"},
           payment_method_id: ba.id,
           payment_method_type: ba.payment_method_type

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(errors: ["amount[cents] must be at least 500"], code: "validation_error"))
    end
  end
end
