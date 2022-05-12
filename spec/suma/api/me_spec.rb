# frozen_string_literal: true

require "suma/api/me"

RSpec.describe Suma::API::Me, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:customer) { Suma::Fixtures.customer.create }

  before(:each) do
    login_as(customer)
  end

  describe "GET /v1/me" do
    it "returns the authed customer" do
      get "/v1/me"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(email: customer.email, ongoing_trip: nil)
    end

    it "errors if the customer is soft deleted" do
      customer.soft_delete

      get "/v1/me"

      expect(last_response).to have_status(401)
    end

    it "401s if not logged in" do
      logout

      get "/v1/me"

      expect(last_response).to have_status(401)
    end

    it "adds a session if the user does not have one" do
      get "/v1/me"
      expect(last_response).to have_status(200)
      expect(Suma::Customer::Session.all).to have_length(1)
      expect(Suma::Customer::Session.last).to have_attributes(customer: be === customer)

      get "/v1/me"
      expect(last_response).to have_status(200)
      expect(Suma::Customer::Session.all).to have_length(1)
    end

    it "returns the customer's ongoing trip if they have one" do
      trip = Suma::Fixtures.mobility_trip.ongoing.create(customer:)

      get "/v1/me"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(ongoing_trip: include(id: trip.id))
    end
  end

  describe "POST /v1/me/update" do
    it "updates the given fields on the customer" do
      post "/v1/me/update", name: "Hassan", other_thing: "abcd"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(name: "Hassan")

      expect(customer.refresh).to have_attributes(name: "Hassan")
    end
  end

  describe "GET /v1/me/dashboard" do
    it "returns the dashboard" do
      cash_ledger = Suma::Fixtures.ledger.customer(customer).category(:cash).create
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$27"))

      get "/v1/me/dashboard"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(payment_account_balance: cost("$27"))
    end
  end
end
