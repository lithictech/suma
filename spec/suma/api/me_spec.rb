# frozen_string_literal: true

require "suma/api/me"

RSpec.describe Suma::API::Me, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/me" do
    it "returns the authed member" do
      get "/v1/me"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(email: member.email, ongoing_trip: nil)
    end

    it "errors if the member is soft deleted" do
      member.soft_delete

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
      expect(Suma::Member::Session.all).to have_length(1)
      expect(Suma::Member::Session.last).to have_attributes(member: be === member)

      get "/v1/me"
      expect(last_response).to have_status(200)
      expect(Suma::Member::Session.all).to have_length(1)
    end

    it "returns the member's ongoing trip if they have one" do
      trip = Suma::Fixtures.mobility_trip.ongoing.create(member:)

      get "/v1/me"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(ongoing_trip: include(id: trip.id))
    end
  end

  describe "POST /v1/me/update" do
    it "updates the given fields on the member" do
      post "/v1/me/update", name: "Hassan", other_thing: "abcd"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(name: "Hassan")

      expect(member.refresh).to have_attributes(name: "Hassan")
    end

    it "can set the address on the member" do
      post "/v1/me/update",
           name: "Hassan",
           address: {address1: "123 Main", city: "Portland", state_or_province: "OR", postal_code: "11111"}

      expect(last_response).to have_status(200)
      expect(member.refresh.legal_entity.address).to have_attributes(address1: "123 Main")
    end
  end

  describe "GET /v1/me/dashboard" do
    it "returns the dashboard" do
      cash_ledger = Suma::Fixtures.ledger.member(member).category(:cash).create
      Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$27"))

      get "/v1/me/dashboard"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(payment_account_balance: cost("$27"), lifetime_savings: cost("$0"), ledger_lines: have_length(1))
    end
  end
end
