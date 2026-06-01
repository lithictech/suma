# frozen_string_literal: true

require "suma/admin_api/anon_proxy_vendor_accounts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::AnonProxyVendorAccounts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  it_behaves_like "an endpoint with subroutes for related resources" do
    let(:detail_route) do
      "/v1/anon_proxy_vendor_accounts/#{Suma::Fixtures.anon_proxy_vendor_account.create.id}"
    end
  end

  describe "GET /v1/anon_proxy_vendor_accounts" do
    it "returns all anon proxy vendor accounts" do
      objs = Array.new(2) { Suma::Fixtures.anon_proxy_vendor_account.create }

      get "/v1/anon_proxy_vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/anon_proxy_vendor_accounts" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.anon_proxy_vendor_account.with_access_code("zzz  123").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.anon_proxy_vendor_account.with_access_code("not magic").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/anon_proxy_vendor_accounts" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.anon_proxy_vendor_account.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/anon_proxy_vendor_accounts" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.anon_proxy_vendor_account.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "GET /v1/anon_proxy_vendor_accounts/:id" do
    it "returns the anon proxy vendor account" do
      config = Suma::Fixtures.anon_proxy_vendor_configuration.create
      member = Suma::Fixtures.member.create
      member_contact = Suma::Fixtures.anon_proxy_member_contact(email: "a@b.c", member:).create
      va = Suma::Fixtures.anon_proxy_vendor_account.with_configuration(config).with_contact(member_contact).create

      get "/v1/anon_proxy_vendor_accounts/#{va.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: va.id,
        configuration: include(id: config.id),
        contact: include(id: member_contact.id),
      )
    end
  end

  describe "POST /v1/anon_proxy_vendor_accounts/:id" do
    it "updates the object" do
      o = Suma::Fixtures.anon_proxy_vendor_account.create

      post "/v1/anon_proxy_vendor_accounts/#{o.id}", pending_closure: true

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(pending_closure: true)
    end
  end

  describe "POST /v1/anon_proxy_vendor_accounts/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.anon_proxy_vendor_account.create

      post "/v1/anon_proxy_vendor_accounts/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(m).to be_destroyed
    end
  end

  describe "POST /v1/anon_proxy_vendor_accounts/:id/revoke_lime_login" do
    it "uses the service revoker" do
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime")
      acct = Suma::Fixtures.anon_proxy_vendor_account(configuration: vc).create
      acct.replace_access_code("x", "https://link").save_changes
      req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link").
        to_return(json_response({}))

      post "/v1/anon_proxy_vendor_accounts/#{acct.id}/revoke_lime_login"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: acct.id)
      expect(req).to have_been_made
    end
  end

  describe "POST /v1/anon_proxy_vendor_accounts/:id/revoke_lime_login/finish" do
    let(:vc) { Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lime") }
    let(:acct) { Suma::Fixtures.anon_proxy_vendor_account(configuration: vc).create(pending_closure: true) }

    it "updates the account" do
      acct.replace_access_code("x", "https://link").save_changes

      post "/v1/anon_proxy_vendor_accounts/#{acct.id}/revoke_lime_login/finish"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: acct.id)
      expect(acct.refresh).to have_attributes(contact: nil, pending_closure: false)
    end

    it "errors if the access code is not set" do
      post "/v1/anon_proxy_vendor_accounts/#{acct.id}/revoke_lime_login/finish"

      expect(last_response).to have_status(409)
    end
  end

  describe "POST /v1/anon_proxy_vendor_accounts/:id/revoke_lyft_pass", no_transaction_check: true do
    before(:each) do
      Suma::Lyft.reset_configuration

      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: {body: {}, cookies: {}}.to_json,
      )

      Suma::Lyft.pass_authorization = "Basic xyz"
      Suma::Lyft.pass_email = "a@b.c"
      Suma::Lyft.pass_org_id = "1234"
    end

    it "revokes registered passes" do
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create(auth_to_vendor_key: "lyft_pass")
      acct = Suma::Fixtures.anon_proxy_vendor_account.create(configuration: vc)
      acct.add_registration(external_program_id: "111")

      req = stub_request(:post, "https://www.lyft.com/api/rideprograms/enrollment/revoke").
        to_return(status: 200)

      post "/v1/anon_proxy_vendor_accounts/#{acct.id}/revoke_lyft_pass"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: acct.id)
      expect(req).to have_been_made
    end
  end
end
