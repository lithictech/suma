# frozen_string_literal: true

require "suma/message"
require "suma/twilio"

RSpec.describe Suma::Message::SmsTransport, :db do
  before(:each) do
    described_class.allowlist = ["*"]
  end
  after(:each) do
    described_class.reset_configuration
  end

  describe "allowlisted?" do
    it "returns true if allowlisted" do
      inst = described_class.new
      inst.allowlist = ["1404*"]
      expect(inst).to be_allowlisted(Suma::Fixtures.message_delivery.sms("404-555-0128").instance)
      expect(inst).to_not be_allowlisted(Suma::Fixtures.message_delivery.sms("454-555-0128").instance)
      expect(inst).to_not be_allowlisted(Suma::Fixtures.message_delivery.sms("invalid").instance)
    end
  end

  describe "send!" do
    it "sends message via Twilio" do
      req = stub_twilio_sms(sid: "SMXYZ").
        with(
          body: {"Body" => "hello", "From" => "15554443333", "To" => "+15554443210"},
          headers: {"Authorization" => "Basic dHdpbGFwaWtleV9zaWQ6dHdpbHNlY3JldA=="},
        )
      delivery = Suma::Fixtures.message_delivery.sms("+15554443210", "hello").create
      result = described_class.new.send!(delivery)
      expect(result).to eq("SMXYZ")
      expect(req).to have_been_made
    end

    it "formats the provided phone number" do
      req = stub_twilio_sms.
        with(body: {"Body" => "hello", "From" => "15554443333", "To" => "+15554443210"})
      delivery = Suma::Fixtures.message_delivery.sms("(555) 444-3210", "hello").create
      described_class.new.send!(delivery)
      expect(req).to have_been_made
    end

    it "raises error if formatted phone is nil" do
      delivery = Suma::Fixtures.message_delivery.sms("invalid").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(/could not format/i)
    end

    it "raises undeliverable if the phone number is not allowlisted" do
      delivery = Suma::Fixtures.message_delivery.sms("404-555-0128").create
      expect do
        sms = described_class.new
        sms.allowlist = []
        sms.send!(delivery)
      end.to raise_error(Suma::Message::Transport::UndeliverableRecipient, /not allowlisted/)
    end

    it "raises undeliverable if the phone number is invalid" do
      req = stub_twilio_sms(fixture: "twilio/send_message_invalid_number", status: 400)
      delivery = Suma::Fixtures.message_delivery.sms("(555) 444-3210", "hello").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(Suma::Message::Transport::UndeliverableRecipient, /twilio_invalid_phone_number/)
      expect(req).to have_been_made
    end
  end

  describe "format_phone" do
    it "returns a phone number in E.164 format with a US country code" do
      expect(described_class.format_phone("5554443210")).to eq("+15554443210")
    end

    it "strips non-numeric characters if present" do
      expect(described_class.format_phone("(555) 444-3210")).to eq("+15554443210")
    end

    it "handles a country code already being present" do
      expect(described_class.format_phone("+1 (555) 444-3210")).to eq("+15554443210")
    end

    it "does not modify a properly formatted US number" do
      expect(described_class.format_phone("+15554443210")).to eq("+15554443210")
    end

    it "returns nil if number is not valid" do
      expect(described_class.format_phone("555444321")).to be nil
      expect(described_class.format_phone("notaphonenumber")).to be nil
      expect(described_class.format_phone("")).to be nil
      expect(described_class.format_phone(nil)).to be nil
    end
  end

  describe "add_bodies" do
    it "renders plain text" do
      delivery = Suma::Fixtures.message_delivery.via(:sms).create
      described_class.new.add_bodies(delivery, Suma::Message::Rendering.new("hello"))
      expect(delivery.bodies).to contain_exactly(have_attributes(content: "hello", mediatype: "text/plain"))
    end

    it "errors if content is not set" do
      delivery = Suma::Fixtures.message_delivery.via(:sms).create
      xport = described_class.new
      expect do
        xport.add_bodies(delivery, "")
      end.to raise_error(/content is not set/i)
    end
  end
end
