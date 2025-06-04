# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::Relay, :db do
  describe Suma::AnonProxy::Relay::FakeEmail do
    let(:relay) { Suma::AnonProxy::Relay.create!("fake-email-relay") }

    it "can parse a row into a message" do
      row = {
        message_id: "m1",
        to: "abc",
        from: "xyz",
        content: "hi",
      }
      e = relay.parse_message(row)
      expect(e).to have_attributes(message_id: "m1", content: "hi", to: "abc", from: "xyz")
    end

    it "can provision" do
      m = Suma::Fixtures.member.create
      expect(relay.provision(m)).to eq("u#{m.id}@example.com")
    end
  end

  describe Suma::AnonProxy::Relay::Postmark do
    let(:relay) { Suma::AnonProxy::Relay.create!("postmark") }

    it "can parse a row into a message" do
      now = Time.now
      row = {
        message_id: "m1",
        to_email: "abc",
        from_email: "xyz",
        timestamp: now,
        data: {"HtmlBody" => "hi"},
      }
      e = relay.parse_message(row)
      expect(e).to have_attributes(
        message_id: "m1", content: "hi", to: "abc", from: "xyz", timestamp: match_time(now),
      )
    end

    it "can provision" do
      m = Suma::Fixtures.member.create
      expect(relay.provision(m)).to eq("test.m#{m.id}@in-dev.mysuma.org")
    end
  end

  describe Suma::AnonProxy::Relay::FakePhone do
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay.create!("fake-phone-relay")
      row = {
        message_id: "m1",
        to: "15552223333",
        from: "15556667777",
        content: "hi",
      }
      e = relay.parse_message(row)
      expect(e).to have_attributes(
        message_id: "m1", content: "hi", to: "15552223333", from: "15556667777",
      )
    end
  end

  describe Suma::AnonProxy::Relay::Signalwire do
    let(:relay) { Suma::AnonProxy::Relay.create!("signalwire") }

    it "can parse a row into a message" do
      now = Time.now
      row = {
        signalwire_id: "m1",
        to: "+15552223333",
        from: "+15556667777",
        date_created: now,
        data: {"body" => "hi"},
      }
      e = relay.parse_message(row)
      expect(e).to have_attributes(
        message_id: "m1", content: "hi", to: "15552223333", from: "15556667777", timestamp: match_time(now),
      )
    end

    it "can provision a phone number", reset_configuration: Suma::Message::SmsTransport do
      Suma::Message::SmsTransport.allowlist = ["*"]
      member = Suma::Fixtures.member.create

      search_req = stub_request(:get, "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers/search?city=Portland&max_results=1&region=OR").
        to_return(fixture_response("signalwire/search_phone_numbers"))
      purchase_req = stub_request(:post, "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers").
        with(body: "{\"number\":\"+15037154424\"}").
        to_return(fixture_response("signalwire/get_phone_number"))
      update_req = stub_request(
        :put,
        "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers/233dffc2-2ad3-455e-a597-0e332c39662a",
      ).with(
        body: {
          name: "(test) AnonProxy - #{member.id}",
          message_handler: "laml_webhooks",
          message_request_url: "http://localhost:22001/api/v1/anon_proxy/relays/signalwire/webhooks",
          message_request_method: "POST",
          message_fallback_url: "http://localhost:22001/api/v1/anon_proxy/relays/signalwire/errors",
          message_fallback_method: "POST",
        }.to_json,
      ).to_return(fixture_response("signalwire/get_phone_number"))

      phone = relay.provision(member)
      expect(phone).to eq("15037154424")

      expect(search_req).to have_been_made
      expect(purchase_req).to have_been_made
      expect(update_req).to have_been_made
    end

    it "errors if the member is not on the SMS allowlist", reset_configuration: Suma::Message::SmsTransport do
      Suma::Message::SmsTransport.allowlist = []
      relay = Suma::AnonProxy::Relay.create!("signalwire")
      expect do
        relay.provision(Suma::Fixtures.member.create)
      end.to raise_error(Suma::InvalidPrecondition)
    end
  end
end
