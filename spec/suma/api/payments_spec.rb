# frozen_string_literal: true

require "suma/api/payments"

RSpec.describe Suma::API::Payments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:customer) { Suma::Fixtures.customer.create }

  before(:each) do
    login_as(customer)
  end

  describe "POST /v1/payments/create_funding" do
    it "creates a new funding and book transaction" do
      ba = Suma::Fixtures.bank_account.customer(customer).verified.create

      post "/v1/payments/create_funding", amount: {cents: 500, currency: "USD"}, bank_account_id: ba.id

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(status: "created")

      expect(customer.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(status: "created", originated_book_transaction: be_present),
      )
      expect(customer.payment_account.cash_ledger.received_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$5")),
      )
      expect(customer.payment_account).to have_attributes(total_balance: cost("$5"))
    end

    it "errors if the bank account is not usable" do
      ba = Suma::Fixtures.bank_account.customer(customer).create
      ba.soft_delete

      post "/v1/payments/create_funding", amount: {cents: 500, currency: "USD"}, bank_account_id: ba.id

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "resource_not_found"))
    end
  end
end
