# frozen_string_literal: true

require "suma/api/anon_proxy"

RSpec.describe Suma::API::AnonProxy, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:fac) { Suma::Fixtures.bank_account.member(member) }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/anon_proxy/vendor_accounts" do
    it "returns vendor accounts" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      vc = Suma::Fixtures.anon_proxy_vendor_configuration.create

      get "/v1/anon_proxy/vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: contain_exactly(
          include(id: va.id),
          include(vendor_slug: vc.vendor.slug),
        ))
    end

    it "can use a default address in formatted instructions" do
      instructions = Suma::TranslatedText.create(en: "see this: %{address}")
      Suma::Fixtures.anon_proxy_vendor_configuration.create(instructions:)

      get "/v1/anon_proxy/vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: contain_exactly(include(instructions: "see this: ")))
    end
  end

  describe "POST /v1/anon_proxy/vendor_accounts/:id/poll_for_new_magic_link" do
    before(:each) do
      # If any test is slow, it's because we're hitting this unexpectedly
      Suma::AnonProxy.access_code_poll_timeout = 10
      Suma::AnonProxy.access_code_poll_interval = 0
    end
    after(:each) do
      Suma::AnonProxy.reset_configuration
    end

    it "handles when there is no code yet set" do
      Suma::AnonProxy.access_code_poll_timeout = 0.001
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create
      va.update(latest_access_code_requested_at: Time.now)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/poll_for_new_magic_link"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: false)
    end

    it "can find when an account changes from one to another access code" do
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).with_access_code("abc").create
      va.update(latest_access_code_requested_at: Time.now)
      va.replace_access_code("def", "http://lime.app/magic_link_token=def").save_changes

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/poll_for_new_magic_link"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: true, vendor_account: include(id: va.id, magic_link: "http://lime.app/magic_link_token=def"))
    end

    it "times out after polling" do
      Suma::AnonProxy.access_code_poll_interval = 2
      va = Suma::Fixtures.anon_proxy_vendor_account(member:).with_access_code("abc", "http://lime.app/magic_link_token=abc").create
      va.update(latest_access_code_requested_at: Time.now)

      expect(Kernel).to receive(:sleep).exactly(5).times do |x|
        Timecop.travel(x.seconds.from_now)
      end

      Timecop.freeze do
        post "/v1/anon_proxy/vendor_accounts/#{va.id}/poll_for_new_magic_link"
      end

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: false, vendor_account: include(id: va.id))
    end
  end

  describe "POST /v1/anon_proxy/vendor_accounts/:id/configure" do
    let(:configuration) { Suma::Fixtures.anon_proxy_vendor_configuration.email.create }
    let!(:va) { Suma::Fixtures.anon_proxy_vendor_account(member:, configuration:).create }

    it "403s if the account does not belong to the member" do
      va.update(member: Suma::Fixtures.member.create)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(message: match(/No anonymous proxy/)))
    end

    it "409s if the configuration is not enabled" do
      configuration.update(enabled: false)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(message: match(/config is not enabled/)))
    end

    it "provisions the email or phone number member contact" do
      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: va.id, all_vendor_accounts: have_same_ids_as(va))

      expect(va.refresh.contact).to have_attributes(email: "u#{member.id}@example.com")
    end

    it "noops if the account is already configured" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member:).email.create
      va.update(contact:)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: va.id, all_vendor_accounts: have_same_ids_as(va))

      expect(va.refresh.contact).to be === contact
    end

    it "formats the account address instructions" do
      contact = Suma::Fixtures.anon_proxy_member_contact(member:).email("x@y.z").create
      va.update(contact:)
      configuration.update(instructions: Suma::TranslatedText.create(en: "see this: %{address}"))

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/configure"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(instructions: "see this: x@y.z")
    end
  end

  describe "POST /v1/anon_proxy/vendor_accounts/:id/make_auth_request" do
    let!(:va) do
      Suma::Fixtures.anon_proxy_vendor_account.with_configuration(
        auth_url: "https://x.y",
        auth_http_method: "POST",
        auth_headers: {"X-Y" => "b"},
      ).with_contact(email: "a@b.c").
        create(member:)
    end

    it "proxies the request and marks the code as requested" do
      req = stub_request(:post, "https://x.y/").
        with(
          body: '{"email":"a@b.c","phone":""}',
          headers: {"X-Y" => "b"},
        ).
        to_return(status: 202, body: '{"o":"k"}', headers: {"Content-Type" => "application/json"})

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/make_auth_request"

      expect(last_response).to have_status(202)
      expect(last_response).to have_json_body.that_includes(o: "k")
      expect(req).to have_been_made
      expect(va.refresh).to have_attributes(latest_access_code_requested_at: match_time(:now))
    end

    it "errors and does not mark code requested on error" do
      req = stub_request(:post, "https://x.y/").
        to_return(status: 400, body: '{"n":"o"}', headers: {"Content-Type" => "application/json"})

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/make_auth_request"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(n: "o")
      expect(req).to have_been_made
      expect(va.refresh).to have_attributes(latest_access_code_requested_at: nil)
    end
  end

  describe "POST /v1/anon_proxy/relays/webhookdb/webhooks" do
    before(:each) do
      logout
    end

    it "enqueues the async jobs" do
      header "Whdb-Webhook-Secret", Suma::Webhookdb.postmark_inbound_messages_secret
      expect(Suma::Async::ProcessAnonProxyInboundWebhookdbRelays).to receive(:perform_async)

      post "/v1/anon_proxy/relays/webhookdb/webhooks", {x: 1}

      expect(last_response).to have_status(202)
    end

    it "errors if the webhook header does not match" do
      post "/v1/anon_proxy/relays/webhookdb/webhooks", {x: 1}

      expect(last_response).to have_status(401)
    end
  end
end
