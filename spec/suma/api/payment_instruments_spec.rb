# frozen_string_literal: true

require "suma/api/payment_instruments"

RSpec.describe Suma::API::PaymentInstruments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }
  let(:bank_fac) { Suma::Fixtures.bank_account.member(member) }

  before(:each) do
    login_as(member)
  end

  describe "POST /v1/payment_instruments/bank_accounts/create" do
    let(:account_number) { "99988877" }
    let(:routing_number) { "111222333" }
    let(:account_type) { "checking" }

    it "creates an unverified bank account" do
      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(200)
      expect(member.refresh.bank_accounts).to contain_exactly(
        have_attributes(name: "Foo", account_number:, routing_number:, verified?: false),
      )
      ba = member.bank_accounts.first
      expect(last_response).to have_json_body.
        that_includes(id: ba.id, all_payment_instruments: have_same_ids_as(ba))
    end

    it "verifies the account automatically if autoverify is enabled" do
      Suma::Payment.autoverify_account_numbers = ["*"]
      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(200)
      expect(member.refresh.bank_accounts).to contain_exactly(have_attributes(verified?: true))
    ensure
      Suma::Payment.reset_configuration
    end

    it "errors if the bank account already exists undeleted for the member" do
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
      expect(member.refresh.bank_accounts).to contain_exactly(be === ba)
      expect(ba.refresh).to have_attributes(name: "Foo")
      expect(last_response).to have_json_body.that_includes(id: member.bank_accounts.first.id)
    end
  end

  describe "DELETE /v1/payment_instruments/bank_accounts/:id" do
    it "soft deletes the bank account" do
      ba = bank_fac.create

      delete "/v1/payment_instruments/bank_accounts/#{ba.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: ba.id, all_payment_instruments: [])
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
