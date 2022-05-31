# frozen_string_literal: true

require "suma/api/payment_instruments"

RSpec.describe Suma::API::PaymentInstruments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:customer) { Suma::Fixtures.customer.create }
  let(:bank_fac) { Suma::Fixtures.bank_account.customer(customer) }

  before(:each) do
    login_as(customer)
  end

  describe "GET /v1/payment_instruments" do
    it "returns all undeleted bank accounts for the customer" do
      deleted_ba = bank_fac.create
      deleted_ba.soft_delete

      ba2 = bank_fac.create
      ba1 = bank_fac.create

      get "/v1/payment_instruments"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ba1, ba2).ordered)
    end
  end

  describe "POST /v1/payment_instruments/bank_accounts/create" do
    let(:account_number) { "99988877" }
    let(:routing_number) { "111222333" }
    let(:account_type) { "checking" }

    it "creates an unverified bank account" do
      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(200)
      expect(customer.refresh.bank_accounts).to contain_exactly(
        have_attributes(name: "Foo", account_number:, routing_number:, verified?: false),
      )
      expect(last_response).to have_json_body.that_includes(id: customer.bank_accounts.first.id)
    end

    it "verifies the account automatically if autoverify is enabled" do
      Suma::Payment.autoverify_account_numbers = ["*"]
      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(200)
      expect(customer.refresh.bank_accounts).to contain_exactly(have_attributes(verified?: true))
    ensure
      Suma::Payment.reset_configuration
    end

    it "errors if the bank account already exists undeleted for the customer" do
      bank_fac.create(account_number:, routing_number:)

      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(code: "conflicting_bank_account"))
    end

    it "undeletes the bank account if it exists as soft deleted" do
      ba = bank_fac.create(account_number:, routing_number:)
      ba.soft_delete

      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(200)
      expect(customer.refresh.bank_accounts).to contain_exactly(be === ba)
      expect(ba.refresh).to have_attributes(name: "Foo")
      expect(last_response).to have_json_body.that_includes(id: customer.bank_accounts.first.id)
    end
  end

  describe "DELETE /v1/payment_instruments/bank_accounts/:id" do
    it "soft deletes the bank account" do
      ba = bank_fac.create

      delete "/v1/payment_instruments/bank_accounts/#{ba.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: ba.id)
      expect(ba.refresh).to be_soft_deleted
    end
    it "errors if the bank account does not belong to the org or is not usable" do
      ba = bank_fac.create
      ba.soft_delete

      delete "/v1/payment_instruments/bank_accounts/#{ba.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "resource_not_found"))
    end
  end
end
