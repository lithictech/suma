# frozen_string_literal: true

require "suma/api/payment_instruments"

RSpec.describe Suma::API::PaymentInstruments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }
  let(:bank_fac) { Suma::Fixtures.bank_account.member(member) }
  let(:card_fac) { Suma::Fixtures.card.member(member) }

  before(:each) do
    login_as(member)
  end

  after(:each) do
    Suma::Payment.reset_configuration
  end

  describe "POST /v1/payment_instruments/bank_accounts/create" do
    let(:account_number) { "99988877" }
    let(:routing_number) { "111222333" }
    let(:account_type) { "checking" }

    it "creates an unverified bank account" do
      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
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

    it "errors if bank accounts are not an enabled method" do
      Suma::Payment.supported_methods = []

      post("/v1/payment_instruments/bank_accounts/create", name: "Foo", account_number:, routing_number:, account_type:)

      expect(last_response).to have_status(402)
      expect(last_response).to have_json_body.that_includes(error: include(code: "forbidden"))
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
    it "errors if the bank account does not belong to the member or is not usable" do
      ba = bank_fac.create
      ba.soft_delete

      delete "/v1/payment_instruments/bank_accounts/#{ba.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "resource_not_found"))
    end
  end

  describe "POST /v1/payment_instruments/cards/create_stripe" do
    it "creates a customer and card using a Stripe token" do
      reqs = [
        stub_request(:post, "https://api.stripe.com/v1/customers").
          to_return(fixture_response("stripe/customer")),
        stub_request(:post, "https://api.stripe.com/v1/customers/cus_D6eGmbqyejk8s9/sources").
          to_return(fixture_response("stripe/card")),
      ]

      post "/v1/payment_instruments/cards/create_stripe", token: load_fixture_data("stripe/token.json", raw: true)

      expect(last_response).to have_status(200)
      expect(reqs).to all(have_been_made)
      expect(last_response.headers).to include("Suma-Current-Member")
      expect(member.refresh.cards).to contain_exactly(
        have_attributes(stripe_id: "card_1CgQyH2eZvKYlo2CYkDQhvma"),
      )
      card = member.cards.first
      expect(last_response).to have_json_body.
        that_includes(id: card.id, all_payment_instruments: have_same_ids_as(card))
    end

    it "handles a customer who is already registered" do
      req = stub_request(:post, "https://api.stripe.com/v1/customers/cus_D6eGmbqyejk8s9/sources").
        to_return(fixture_response("stripe/card"))

      member.update(stripe_customer_json: load_fixture_data("stripe/customer"))
      post "/v1/payment_instruments/cards/create_stripe", token: load_fixture_data("stripe/token.json", raw: true)

      expect(last_response).to have_status(200)
      expect(req).to have_been_made
      expect(member.refresh.cards).to contain_exactly(
        have_attributes(stripe_id: "card_1CgQyH2eZvKYlo2CYkDQhvma"),
      )
    end

    it "errors if Stripe errors on card create" do
      req = stub_request(:post, "https://api.stripe.com/v1/customers/cus_D6eGmbqyejk8s9/sources").
        to_return(fixture_response("stripe/charge_error", status: 402))

      member.update(stripe_customer_json: load_fixture_data("stripe/customer"))

      post "/v1/payment_instruments/cards/create_stripe", token: load_fixture_data("stripe/token.json", raw: true)

      expect(req).to have_been_made
      expect(last_response).to have_status(402)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "card_permanent_failure"))
    end

    it "errors if bank accounts are not an enabled method" do
      Suma::Payment.supported_methods = []

      post "/v1/payment_instruments/cards/create_stripe", token: load_fixture_data("stripe/token.json", raw: true)

      expect(last_response).to have_status(402)
      expect(last_response).to have_json_body.that_includes(error: include(code: "forbidden"))
    end
  end

  describe "DELETE /v1/payment_instruments/cards/:id" do
    it "soft deletes the card and deletes it in Stripe" do
      card = card_fac.create
      stub_request(:delete, "https://api.stripe.com/v1/customers/cus_cardowner/sources/#{card.stripe_id}").
        to_return(fixture_response(body: "{}"))

      delete "/v1/payment_instruments/cards/#{card.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: card.id, all_payment_instruments: [])
      expect(card.refresh).to be_soft_deleted
    end
    it "errors if the card does not belong to the member or is not usable" do
      card = card_fac.create
      card.soft_delete

      delete "/v1/payment_instruments/cards/#{card.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "resource_not_found"))
    end
  end
end
