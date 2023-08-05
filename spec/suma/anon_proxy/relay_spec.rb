# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::Relay, :db do
  describe Suma::AnonProxy::Relay::Fake do
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay::Fake.new
      row = {
        message_id: "m1",
        to: "abc",
        from: "xyz",
        content: "hi",
      }
      e = relay.parse_message(row)
      expect(e).to have_attributes(message_id: "m1", content: "hi", to: "abc", from: "xyz")
    end
  end

  describe Suma::AnonProxy::Relay::Postmark, reset_configuration: Suma::AnonProxy do
    let(:relay) { Suma::AnonProxy::Relay.create!("postmark") }

    it "can provision an email for a member" do
      me = Suma::Fixtures.member.create
      me.values[:id] = 5
      expect(relay.provision(me)).to eq("test.m5@in-dev.mysuma.org")
    end

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
  end

  describe Suma::AnonProxy::Relay::Plivo do
    let(:relay) { Suma::AnonProxy::Relay.create!("plivo") }

    it "can provision a number for a member" do
      search = stub_request(:get, "https://api.plivo.com/v1/Account/MA_FAKE_A4NTUWNMEYZW/PhoneNumber/?country_iso=US&limit=1&services=sms").
        to_return(fixture_response("plivo/phone_search"))
      buy = stub_request(:post, "https://api.plivo.com/v1/Account/MA_FAKE_A4NTUWNMEYZW/PhoneNumber/14154009186/").
        to_return(fixture_response("plivo/phone_buy_success"))

      me = Suma::Fixtures.member.create
      expect(relay.provision(me)).to eq("14154009186")
      expect([search, buy]).to all(have_been_made)
    end

    it "errors if the phone number is pending" do
      search = stub_request(:get, "https://api.plivo.com/v1/Account/MA_FAKE_A4NTUWNMEYZW/PhoneNumber/?country_iso=US&limit=1&services=sms").
        to_return(fixture_response("plivo/phone_search"))
      buy = stub_request(:post, "https://api.plivo.com/v1/Account/MA_FAKE_A4NTUWNMEYZW/PhoneNumber/14154009186/").
        to_return(fixture_response("plivo/phone_buy_pending"))

      me = Suma::Fixtures.member.create
      expect do
        relay.provision(me)
      end.to raise_error(described_class::PendingPhonePurchase)
      expect([search, buy]).to all(have_been_made)
    end

    it "can parse a row into a message" do
      now = Time.now
      row = {
        plivo_message_uuid: "m1",
        to_number: "abc",
        from_number: "xyz",
        message_time: now,
        data: {"Text" => "hi"},
      }
      e = relay.parse_message(row)
      expect(e).to have_attributes(
        message_id: "m1", content: "hi", to: "abc", from: "xyz", timestamp: match_time(now),
      )
    end
  end
end
