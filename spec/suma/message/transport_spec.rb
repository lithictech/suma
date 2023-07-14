# frozen_string_literal: true

require "suma/message"
require "suma/twilio"

RSpec.describe Suma::Message::Transport, :db do
  describe "for" do
    it "returns a new transport instance", reset_configuration: Suma::Message::SmsTransport do
      Suma::Message::SmsTransport.allowlist = ["99"]
      t = described_class.for("sms")
      expect(t).to be_a(Suma::Message::SmsTransport)
      expect(t.allowlist).to eq(["99"])
    end

    it "can error for an invalid type" do
      expect(described_class.for("foo")).to be_nil
      expect { described_class.for!("foo") }.to raise_error(Suma::Message::InvalidTransportError)
    end

    it "can use an override" do
      described_class.override = "sms"
      t = described_class.for("invalid")
      expect(t).to be_a(Suma::Message::SmsTransport)
    ensure
      described_class.override = nil
    end
  end
end
