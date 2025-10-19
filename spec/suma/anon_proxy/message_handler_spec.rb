# frozen_string_literal: true

require "url_shortener/spec_helpers"

RSpec.describe Suma::AnonProxy::MessageHandler, :db do
  include UrlShortener::SpecHelpers
  let(:url_shortener) { Suma::UrlShortener.shortener }

  before(:each) do
    described_class::Fake.reset
  end

  describe "handle" do
    let(:relay) { Suma::AnonProxy::Relay.create!("fake-email-relay") }
    let(:fake_handler) { Suma::AnonProxy::MessageHandler.registry_create!("fake-handler") }

    it "noops for old messages" do
      older = relay.parse_message({from: "fake-email-relay", timestamp: 20.minutes.ago})
      expect(described_class.handle(relay, older)).to be_nil
      expect(fake_handler.class.handled).to be_empty
    end

    it "logs a warning and returns nil if no handler can handle" do
      timestamp = "2100-01-01T00:00:00Z"
      msg = relay.parse_message({from: "nomatch", timestamp:})
      logs = capture_logs_from(described_class.logger, level: :warn, formatter: :json) do
        expect(described_class.handle(relay, msg)).to be_nil
      end
      expect(fake_handler.class.handled).to be_empty
      expect(logs).to include(
        include_json(
          message: eq("no_handler_for_message"),
          context: {
            message: {from: "nomatch", timestamp:},
          },
        ),
      )
    end

    it "logs a warning and returns nil if no vendor account is found" do
      fake_handler.class.can_handle_callback = proc { true }
      msg = relay.parse_message({from: "fake-email-relay", timestamp: Time.now, to: "x@y.z"})
      logs = capture_logs_from(described_class.logger, level: :warn, formatter: :json) do
        expect(described_class.handle(relay, msg)).to be_nil
      end
      expect(fake_handler.class.handled).to be_empty
      expect(logs).to include(include_json(message: eq("no_vendor_account_for_message")))
    end

    describe "with a handleable message" do
      let(:vendor_account) { Suma::Fixtures.anon_proxy_vendor_account.with_contact.create }
      let(:message) do
        relay.parse_message({
                              message_id: "m1",
                              from: "fake-email-relay",
                              timestamp: Time.now,
                              to: vendor_account.contact.email,
                              content: "hello",
                            })
      end

      it "saves a new vendor account message" do
        fake_handler.class.can_handle_callback = proc { true }
        fake_handler.class.handle_callback = proc do
          d = Suma::Fixtures.message_delivery(recipient: vendor_account.member, transport_message_id: "xyz").create
          Suma::AnonProxy::MessageHandler::Result.new(handled: true, outbound_delivery: d)
        end
        vam = described_class.handle(relay, message)
        expect(vam).to have_attributes(
          message_id: "m1",
          vendor_account: be === vendor_account,
          outbound_delivery: have_attributes(transport_message_id: "xyz"),
        )
        expect(fake_handler.class.handled).to contain_exactly(be === vam)
      end

      it "returns nil if no delivery is returned" do
        fake_handler.class.can_handle_callback = proc { true }
        expect(described_class.handle(relay, message)).to be_nil
        expect(fake_handler.class.handled).to contain_exactly(have_attributes(id: nil, outbound_delivery: nil))
      end
    end
  end

  describe Suma::AnonProxy::MessageHandler::Lime do
    let(:lime) { Suma::AnonProxy::MessageHandler.registry_create!(described_class.new.key) }
    let(:vendor_config) { Suma::Fixtures.anon_proxy_vendor_configuration(message_handler_key: lime.key).create }
    let(:vendor_account) do
      Suma::Fixtures.anon_proxy_vendor_account(configuration: vendor_config).with_contact.create
    end
    def create_message(file)
      email = load_fixture_data(file)
      content = JSON.parse(email["data"]).fetch("HtmlBody")
      Suma::AnonProxy::ParsedMessage.new(
        message_id: "msg1",
        to: vendor_account.contact.email,
        from: described_class::NOREPLY,
        content:,
        timestamp: Time.now,
      )
    end
    let(:signin_message) { create_message("webhookdb/lime_access_code_postmark_email") }
    let(:confirm_message) { create_message("webhookdb/lime_access_code_confirm_postmark_email") }
    let(:api_signin_message) { create_message("webhookdb/lime_access_code_api_signin_postmark_email") }

    before(:each) do
      import_localized_message_seeds
      Suma::Payment.ensure_cash_ledger(vendor_account.member)
      Suma::Payment.minimum_cash_balance_for_services_cents = -5
    end

    it "handles messages from no-reply" do
      expect(lime).to be_can_handle(signin_message)
    end

    it "parses an access code and assigns it to the vendor account" do
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-email-relay"),
        signin_message,
      )
      expect(got).to have_attributes(vendor_account:, outbound_delivery: nil)
      expect(vendor_account.refresh).to have_attributes(
        latest_access_code: "M1ZgpMepjL5kW9XgzCmnsBKQ",
        latest_access_code_magic_link: start_with("http://localhost:22001/r/"),
        latest_access_code_set_at: match_time(:now),
      )
      expect(Suma::UrlShortener.shortener.dataset.order(:inserted_at).last).to include(
        url: "https://limebike.app.link/login?magic_link_token=M1ZgpMepjL5kW9XgzCmnsBKQ",
        short_id: vendor_account.latest_access_code_magic_link.split("/").last,
      )
    end

    it "can skip url shortening", reset_configuration: Suma::UrlShortener do
      Suma::UrlShortener.disabled = true
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-email-relay"),
        signin_message,
      )
      expect(got).to have_attributes(vendor_account:, outbound_delivery: nil)
      expect(vendor_account.refresh).to have_attributes(
        latest_access_code: "M1ZgpMepjL5kW9XgzCmnsBKQ",
        latest_access_code_magic_link: start_with("https://limebike.app.link"),
        latest_access_code_set_at: match_time(:now),
      )
    end

    it "parses an confirmation access code code, assigns it to the vendor account, and sends it via SMS" do
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-email-relay"),
        confirm_message,
      )
      expect(got).to have_attributes(vendor_account:, outbound_delivery: nil)
      expect(vendor_account.refresh).to have_attributes(
        latest_access_code: "hXYamQ1JGVifc6xuMv6qUrLZ",
        latest_access_code_magic_link: be_a_shortlink_to(
          "https://limebike.app.link/email_verification?authentication_code=hXYamQ1JGVifc6xuMv6qUrLZ",
        ),
        latest_access_code_set_at: match_time(:now),
      )
      expect(vendor_account.contact.member.message_deliveries.last).to have_attributes(
        template: "anon_proxy/lime_deep_link_access_code",
        transport_type: "sms",
        carrier_key: "signalwire",
      )
    end

    it "parses the lime api signin message" do
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-email-relay"),
        api_signin_message,
      )
      expect(got).to have_attributes(vendor_account:, outbound_delivery: nil)
      expect(vendor_account.refresh).to have_attributes(
        latest_access_code: "M1ZgpMepjL5kX9XgzCmnsBKQ",
        latest_access_code_magic_link: be_a_shortlink_to("https://web-production.lime.bike/api/rider/v2/magic-challenge?magic_link_token=M1ZgpMepjL5kX9XgzCmnsBKQ"),
        latest_access_code_set_at: match_time(:now),
      )
      expect(vendor_account.contact.member.message_deliveries.last).to have_attributes(
        template: "anon_proxy/lime_deep_link_access_code",
        transport_type: "sms",
        carrier_key: "signalwire",
      )
    end

    it "noops if we do not recognize the message" do
      signin_message.content.gsub!(
        "https://limebike.app.link/login?magic_link_token=M1ZgpMepjL5kW9XgzCmnsBKQ",
        "https://limebike.app.link/login?totall_normal_token=M1ZgpMepjL5kW9XgzCmnsBKQ",
      )
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-email-relay"),
        signin_message,
      )
      expect(got).to be_nil
      expect(vendor_account.contact.member.message_deliveries).to be_empty
    end

    describe "when the vendor account has a pending closure" do
      before(:each) do
        vendor_account.update(pending_closure: true)
      end

      it "logs in the user if the vendor account has a pending closure" do
        req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/login").
          with(
            body: {
              "has_virtual_card" => "false",
              "magic_link_token" => "M1ZgpMepjL5kW9XgzCmnsBKQ",
              "user_agreement_country_code" => "US", "user_agreement_version" => "5",
            },
          ).to_return(fixture_response("lime/app_post_magic_link"))

        got = Suma::AnonProxy::MessageHandler.handle(
          Suma::AnonProxy::Relay.create!("fake-email-relay"),
          signin_message,
        )

        expect(req).to have_been_made
        expect(got).to have_attributes(vendor_account:, outbound_delivery: nil)
        expect(vendor_account.refresh).to have_attributes(latest_access_code: nil, pending_closure: false)
      end

      it "ignores NoToken errors" do
        req = stub_request(:post, "https://web-production.lime.bike/api/rider/v2/onboarding/login").
          to_return(fixture_response("lime/app_post_sign_terms"))

        Suma::AnonProxy::MessageHandler.handle(
          Suma::AnonProxy::Relay.create!("fake-email-relay"),
          signin_message,
        )

        expect(req).to have_been_made
        expect(vendor_account.refresh).to have_attributes(pending_closure: false)
      end
    end

    describe "when the member's payment account cannot use services" do
      before(:each) do
        Suma::Payment.minimum_cash_balance_for_services_cents = 5
      end

      it "calls Sentry and does not set the url" do
        expect(Suma::Payment).to_not be_can_use_services(vendor_account.member.payment_account)
        got = Suma::AnonProxy::MessageHandler.handle(
          Suma::AnonProxy::Relay.create!("fake-email-relay"),
          signin_message,
        )
        expect(got).to have_attributes(vendor_account:, outbound_delivery: nil)
        expect(vendor_account.refresh).to have_attributes(latest_access_code: nil)
      end
    end
  end
end
