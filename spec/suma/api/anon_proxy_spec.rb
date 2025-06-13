# frozen_string_literal: true

require "suma/api/anon_proxy"

RSpec.describe Suma::API::AnonProxy, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:fac) { Suma::Fixtures.bank_account.member(member) }

  before(:each) do
    login_as(member)
    Suma::AnonProxy::AuthToVendor::Fake.reset
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
  end

  describe "POST /v1/anon_proxy/vendor_accounts/:id/poll_for_new_magic_link" do
    before(:each) do
      # If any test is slow, it's because we're hitting this unexpectedly
      Suma::AnonProxy.access_code_poll_timeout = 10
      Suma::AnonProxy.access_code_poll_interval = 0
      Suma::AnonProxy::AuthToVendor::Fake.needs_polling = true
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

    it "returns immediately if the vendor does not need polling" do
      Suma::AnonProxy::AuthToVendor::Fake.needs_polling = false

      va = Suma::Fixtures.anon_proxy_vendor_account(member:).create

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/poll_for_new_magic_link"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(found_change: true)
    end
  end

  describe "POST /v1/anon_proxy/vendor_accounts/:id/make_auth_request" do
    let!(:va) do
      Suma::Fixtures.anon_proxy_vendor_account.
        with_configuration(auth_to_vendor_key: "fake").
        with_contact(email: "a@b.c").
        create(member:)
    end

    it "403s if the account does not belong to the member" do
      va.update(member: Suma::Fixtures.member.create)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/make_auth_request"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(message: match(/No anonymous proxy/)))
    end

    it "409s if the configuration is not enabled" do
      va.configuration.update(enabled: false)

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/make_auth_request"

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(message: match(/config is not enabled/)))
    end

    it "auths to vendor and marks the code as requested" do
      post "/v1/anon_proxy/vendor_accounts/#{va.id}/make_auth_request"

      expect(last_response).to have_status(200)
      expect(va.refresh).to have_attributes(latest_access_code_requested_at: match_time(:now))
      expect(Suma::AnonProxy::AuthToVendor::Fake.calls).to eq(1)
    end

    it "errors and does not mark code requested on error" do
      Suma::AnonProxy::AuthToVendor::Fake.auth = proc { raise "hello!" }

      post "/v1/anon_proxy/vendor_accounts/#{va.id}/make_auth_request"

      expect(last_response).to have_status(500)
      expect(va.refresh).to have_attributes(latest_access_code_requested_at: nil)
    end
  end

  describe "POST /v1/anon_proxy/relays/webhookdb/webhooks" do
    before(:each) do
      logout
    end

    it "enqueues the async jobs", sidekiq: :fake do
      header "Whdb-Webhook-Secret", Suma::Webhookdb.postmark_inbound_messages_secret

      post "/v1/anon_proxy/relays/webhookdb/webhooks", {x: 1}

      expect(last_response).to have_status(202)
      expect(Suma::Async::ProcessAnonProxyInboundWebhookdbRelays.jobs).to have_length(1)
    end

    it "errors if the webhook header does not match" do
      post "/v1/anon_proxy/relays/webhookdb/webhooks", {x: 1}

      expect(last_response).to have_status(401)
    end
  end

  describe "POST /v1/anon_proxy/relays/signalwire/webhooks",
           reset_configuration: [Suma::AnonProxy, Suma::Message::SmsTransport] do
    let(:body) do
      {
        "MessageSid" => "1aba0c32-0e59-4b62-9541-dc73a1fb04a9",
        "SmsSid" => "1aba0c32-0e59-4b62-9541-dc73a1fb04a9",
        "AccountSid" => "0ef28bae-a4f0-437e-95b8-eab92d15162e",
        "From" => "+15556661603",
        "To" => "+15552221111",
        "Body" => "Test message",
        "NumMedia" => "0",
        "NumSegments" => "1",
      }
    end

    it "returns LaML for a matched member contact" do
      Suma::Message::SmsTransport.allowlist = ["*"]
      Suma::AnonProxy.signalwire_relay_number = "15559994444"
      mc = Suma::Fixtures.anon_proxy_member_contact.phone("15552221111").create
      mc.member.update(phone: "15558889999")

      post "/v1/anon_proxy/relays/signalwire/webhooks", body

      expect(last_response).to have_status(200)
      expect(last_response.headers["Content-Type"]).to eq("application/xml")
      expect(last_response.body).to include(
        '<Message from="+15559994444" to="+15558889999">From (555) 666-1603: Test message',
      )
    end

    it "can handle messages sent from a shortcode" do
      Suma::Message::SmsTransport.allowlist = ["*"]
      Suma::AnonProxy.signalwire_relay_number = "15559994444"
      mc = Suma::Fixtures.anon_proxy_member_contact.phone("15552221111").create
      mc.member.update(phone: "15558889999")

      body["From"] = "22395"

      post "/v1/anon_proxy/relays/signalwire/webhooks", body

      expect(last_response).to have_status(200)
      expect(last_response.body).to include(
        '<Message from="+15559994444" to="+15558889999">From 22395: Test message',
      )
    end

    it "return empty for no matching member contact" do
      Suma::Message::SmsTransport.allowlist = ["*"]
      expect(Sentry).to receive(:capture_message).with("Received webhook for signalwire for unmatched number")

      post "/v1/anon_proxy/relays/signalwire/webhooks", body

      expect(last_response).to have_status(200)
      expect(last_response.headers["Content-Type"]).to eq("application/xml")
      expect(last_response.body).to include("<Response></Response>")
    end

    it "return empty if the member contact member phone is not on the sms allowlist" do
      Suma::Message::SmsTransport.allowlist = []
      Suma::AnonProxy.signalwire_relay_number = "15559994444"
      mc = Suma::Fixtures.anon_proxy_member_contact.phone("15552221111").create
      mc.member.update(phone: "15558889999")

      expect(Sentry).to receive(:capture_message).with("Received webhook for signalwire to not-allowlisted phone")

      post "/v1/anon_proxy/relays/signalwire/webhooks", body

      expect(last_response).to have_status(200)
      expect(last_response.headers["Content-Type"]).to eq("application/xml")
      expect(last_response.body).to include("<Response></Response>")
    end
  end

  describe "POST /v1/anon_proxy/relays/signalwire/errors" do
    it "records the error in Sentry" do
      expect(Sentry).to receive(:capture_message)

      post "/v1/anon_proxy/relays/signalwire/errors", {x: 1}

      expect(last_response).to have_status(200)
    end
  end
end
