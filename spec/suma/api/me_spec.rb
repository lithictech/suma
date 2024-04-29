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
      expect(last_response.headers).to include("Cache-Control" => "no-store")
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

    describe "when authed as an admin" do
      let(:admin) { Suma::Fixtures.member.admin.create }
      before(:each) do
        logout
        login_as_admin(admin)
      end

      it "returns the impersonated user if they are impersonated" do
        target = Suma::Fixtures.member.create

        impersonate(admin:, target:)

        get "/v1/me"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(id: target.id, admin_member: include(id: admin.id))
      end

      it "does not include 'impersonating' if not impersonating" do
        get "/v1/me"
        expect(last_response).to have_status(200)
        expect(last_response_json_body).to_not include(:admin_member)
      end
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

    it "ensures an organization membership with the given name" do
      post "/v1/me/update", organization_name: "Hacienda ABC"

      expect(last_response).to have_status(200)
      expect(member.organization_memberships).to contain_exactly(
        have_attributes(unverified_organization_name: "Hacienda ABC"),
      )
    end

    it "creates member summary if organization does not exist" do
      post "/v1/me/update", organization: {name: "external org"}

      expect(last_response).to have_status(200)
      expect(member.activities.last.summary).to eq("Added external affiliated organization: external org")
    end
  end

  describe "POST /v1/me/language" do
    it "modifies message preferences language" do
      post "/v1/me/language", language: "es"

      expect(last_response).to have_status(200)
      expect(member.refresh.message_preferences).to have_attributes(preferred_language: "es")
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

  describe "POST /v1/me/waitlist" do
    def keyvalues_ds
      return member.db[:member_key_values].where(member_id: member.id)
    end

    it "marks the user as waitlisted for the given feature" do
      post "/v1/me/waitlist", feature: "food"
      expect(last_response).to have_status(200)
      post "/v1/me/waitlist", feature: "utilities"
      expect(last_response).to have_status(200)
      post "/v1/me/waitlist", feature: "mobility"
      expect(last_response).to have_status(200)
      expect(keyvalues_ds.all).to contain_exactly(
        include(key: "waitlist_food"),
        include(key: "waitlist_utilities"),
        include(key: "waitlist_mobility"),
      )
    end

    it "does not update an existing feature" do
      post "/v1/me/waitlist", feature: "food"
      expect(last_response).to have_status(200)
      expect(keyvalues_ds.all).to contain_exactly(include(key: "waitlist_food"))

      post "/v1/me/waitlist", feature: "food"
      expect(last_response).to have_status(200)
      expect(keyvalues_ds.all).to contain_exactly(include(key: "waitlist_food"))
    end
  end
end
