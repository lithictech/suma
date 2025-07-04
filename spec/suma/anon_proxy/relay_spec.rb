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
      Timecop.travel("2025-06-20T12:00:00-0700") do
        expect(relay.provision(m)).to have_attributes(address: "u#{m.id}.1750446000@example.com")
      end
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
      Timecop.travel("2025-06-20T12:00:00-0700") do
        expect(relay.provision(m)).to have_attributes(address: "test.m#{m.id}.1750446000@in-dev.mysuma.org")
      end
    end

    it "can provision in production, so there is no prefix" do
      stub_const("Suma::RACK_ENV", "production")
      m = Suma::Fixtures.member.create
      Timecop.travel("2025-06-20T12:00:00-0700") do
        expect(relay.provision(m)).to have_attributes(address: "m#{m.id}.1750446000@in-dev.mysuma.org")
      end
    end

    it "can deprovision" do
      addr = described_class::ProvisionedAddress.new("a@b.c")
      expect { relay.deprovision(addr) }.to_not raise_error
    end

    it "has a webhookdb dataset" do
      expect(relay.webhookdb_dataset.all).to be_empty
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

    it "can provision a phone number", reset_configuration: Suma::Message::Transport::Sms do
      Suma::Message::Transport::Sms.allowlist = ["*"]
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

      prov = relay.provision(member)
      expect(prov).to have_attributes(address: "15037154424", external_id: "233dffc2-2ad3-455e-a597-0e332c39662a")

      expect(search_req).to have_been_made
      expect(purchase_req).to have_been_made
      expect(update_req).to have_been_made
    end

    it "errors if the member is not on the SMS allowlist", reset_configuration: Suma::Message::Transport::Sms do
      Suma::Message::Transport::Sms.allowlist = []
      expect do
        relay.provision(Suma::Fixtures.member.create)
      end.to raise_error(Suma::InvalidPrecondition)
    end

    describe "webhookdb_dataset" do
      it "includes only inbound messages" do
        Suma::Webhookdb.signalwire_messages_dataset.insert(signalwire_id: "m1", direction: "inbound", data: "{}")
        Suma::Webhookdb.signalwire_messages_dataset.insert(signalwire_id: "m2", direction: "outbound", data: "{}")

        expect(relay.webhookdb_dataset.all).to contain_exactly(include(signalwire_id: "m1"))
      end
    end

    describe "deprovisioning" do
      let(:addr) { Suma::AnonProxy::Relay::ProvisionedAddress.new("12223334444", external_id: "xyz") }

      it "deletes the referenced number" do
        req = stub_request(:delete, "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers/xyz").
          to_return(status: 204, body: "")
        relay.deprovision(addr)
        expect(req).to have_been_made
      end

      it "noops if the phone number does not exist" do
        req = stub_request(:delete, "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers/xyz").
          to_return(status: 404, body: "Not found")
        relay.deprovision(addr)
        expect(req).to have_been_made
      end

      it "raises other errors" do
        req = stub_request(:delete, "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers/xyz").
          to_return(status: 500, body: "Error")
        expect { relay.deprovision(addr) }.to raise_error(Suma::Http::Error)
        expect(req).to have_been_made
      end

      it "schedules a new job if the number cannot be released", sidekiq: :fake do
        req = stub_request(:delete, "https://sumafaketest.signalwire.com/api/relay/rest/phone_numbers/xyz").
          to_return(fixture_response("signalwire/error_phone_cannot_release", status: 422))
        Timecop.freeze("2025-06-01T12:00:00Z") do
          relay.deprovision(addr)
        end
        expect(req).to have_been_made
        expect(Suma::Async::AnonProxyMemberContactDestroyedResourceCleanup.jobs).to contain_exactly(
          include(
            "at" => Time.parse("2025-06-18 06:49:47 UTC").to_i,
            "args" => [{"address" => "12223334444", "external_id" => "xyz", "relay_key" => "signalwire"}],
          ),
        )
      end
    end
  end
end
