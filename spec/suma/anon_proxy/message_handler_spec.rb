# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::MessageHandler, :db do
  before(:each) do
    described_class::Fake.reset
  end

  describe "handle" do
    let(:relay) { Suma::AnonProxy::Relay.create!("fake-relay") }
    let(:fake_handler) { Suma::AnonProxy::MessageHandler.create!("fake-handler") }

    it "noops for old messages" do
      older = relay.parse_message({from: "fake-relay", timestamp: 20.minutes.ago})
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
      msg = relay.parse_message({from: "fake-relay", timestamp: Time.now, to: "x@y.z"})
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
                              from: "fake-relay",
                              timestamp: Time.now,
                              to: vendor_account.contact.email,
                              content: "hello",
                            })
      end

      it "saves a new vendor account message" do
        fake_handler.class.can_handle_callback = proc { true }
        fake_handler.class.handle_callback = proc do
          Suma::Fixtures.message_delivery(recipient: vendor_account.member, transport_message_id: "xyz").create
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
    let(:lime) { Suma::AnonProxy::MessageHandler.create!(described_class.new.key) }
    let(:vendor_config) { Suma::Fixtures.anon_proxy_vendor_configuration(message_handler_key: lime.key).create }
    let(:vendor_account) do
      Suma::Fixtures.anon_proxy_vendor_account(configuration: vendor_config).with_contact.create
    end
    let(:message) do
      email = load_fixture_data("webhookdb/lime_access_code_postmark_email")
      content = JSON.parse(email["data"]).fetch("HtmlBody")
      Suma::AnonProxy::ParsedMessage.new(
        message_id: "msg1",
        to: vendor_account.contact.email,
        from: described_class::NOREPLY,
        content:,
        timestamp: Time.now,
      )
    end

    it "handles messages from no-reply" do
      expect(lime).to be_can_handle(message)
    end

    # rubocop:disable Layout/LineLength
    it "parses an access code and sends it via SMS" do
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-relay"),
        message,
      )
      expect(vendor_account.contact.member.message_deliveries).to contain_exactly(be === got.outbound_delivery)
      expect(got.outbound_delivery).to have_attributes(to: vendor_account.contact.member.phone)
      expect(got.outbound_delivery.bodies.first).to have_attributes(
        content: "Verify your Lime account with this link https://limebike.app.link/login?magic_link_token=M1ZgpMepjL5kW9XgzCmnsBKQ or this code: M1ZgpMepjL5kX9XgzCmnsBKQ",
      )
    end
    # rubocop:enable Layout/LineLength

    it "noops if we do not recognize the message" do
      message.content.gsub!(/copy and paste/, "foo and bar")
      got = Suma::AnonProxy::MessageHandler.handle(
        Suma::AnonProxy::Relay.create!("fake-relay"),
        message,
      )
      expect(got).to be_nil
      expect(vendor_account.contact.member.message_deliveries).to be_empty
    end
  end
end
