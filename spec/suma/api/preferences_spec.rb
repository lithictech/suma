# frozen_string_literal: true

require "suma/api/preferences"

RSpec.describe Suma::API::Preferences, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create(name: "Pedro Pascal") }

  describe "GET /v1/preferences/public" do
    it "returns prefs if the prefs access token is given" do
      get "/v1/preferences/public", access_token: member.preferences!.access_token

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        name: "Pe***al",
        preferences: include(
          subscriptions: [
            {key: "account_updates", opted_in: true, editable_state: "on"},
            {key: "marketing", opted_in: true, editable_state: "on"},
            {key: "security", opted_in: true, editable_state: "off"},
          ],
        ),
      )
    end

    it "401s for an invalid access token" do
      get "/v1/preferences/public", access_token: "abcd"

      expect(last_response).to have_status(401)
    end

    it "401s for a deleted member" do
      member.soft_delete
      get "/v1/preferences/public", access_token: member.preferences!.access_token

      expect(last_response).to have_status(401)
    end
  end

  describe "POST /v1/preferences/public" do
    it "updates prefs of the user with the access token" do
      post "/v1/preferences/public",
           access_token: member.preferences!.access_token,
           subscriptions: {account_updates: false}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        name: "Pe***al",
        preferences: include(
          subscriptions: include(hash_including({key: "account_updates", opted_in: false, editable_state: "on"})),
        ),
      )
      expect(member.preferences.refresh).to have_attributes(account_updates_optout: true)
    end

    it "sync oye contact sms preferences when marketing key is passed" do
      member.update(oye_contact_id: "1")
      contact_status_update_req = stub_request(:put, "https://app.oyetext.org/api/v1/contacts/bulk_update").
        to_return(fixture_response("oye/bulk_update_contacts"), status: 200)

      post "/v1/preferences/public",
           access_token: member.preferences!.access_token,
           subscriptions: {marketing: false}

      expect(last_response).to have_status(200)
      expect(contact_status_update_req).to have_been_made
      expect(member.preferences.refresh).to have_attributes(marketing_optout: true)
    end

    it "401s for an invalid access token" do
      post "/v1/preferences/public", access_token: "abcd", subscriptions: {}

      expect(last_response).to have_status(401)
    end

    it "errors for an invalid subscription key" do
      post "/v1/preferences/public",
           access_token: member.preferences!.access_token,
           subscriptions: {foo: false}

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Subscription foo is invalid"))
    end

    it "errors for an invalid subscription value" do
      post "/v1/preferences/public",
           access_token: member.preferences!.access_token,
           subscriptions: {account_updates: nil}

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Subscription value account_updates must be a bool"))
    end
  end

  describe "POST /v1/preferences" do
    before(:each) do
      login_as(member)
    end

    it "updates prefs of the authed user" do
      post "/v1/preferences", subscriptions: {account_updates: false}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        name: "Pedro Pascal",
        preferences: include(
          subscriptions: include(hash_including({key: "account_updates", opted_in: false, editable_state: "on"})),
        ),
      )
      expect(member.preferences.refresh).to have_attributes(account_updates_optout: true)
    end

    it "401s if the user cannot auth" do
      logout

      post "/v1/preferences", subscriptions: {account_updates: false}

      expect(last_response).to have_status(401)
    end
  end
end
