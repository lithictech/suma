# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::Relay, :db do
  describe Suma::AnonProxy::Relay::FakeEmail do
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay::create!('fake-phone-relay')
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

  describe Suma::AnonProxy::Relay::Postmark do
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay.create!("postmark")
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

  describe Suma::AnonProxy::Relay::FakePhone do
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay.create!("fake-phone-relay")
      now = Time.now
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
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay.create!("signalwire")
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
  end
end
