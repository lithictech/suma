# frozen_string_literal: true

RSpec.describe Suma::AnonProxy::Relay, :db do
  describe Suma::AnonProxy::Relay::FakeEmail do
    it "can parse a row into a message" do
      relay = Suma::AnonProxy::Relay::FakeEmail.new
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
end
