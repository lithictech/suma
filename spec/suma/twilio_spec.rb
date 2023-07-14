# frozen_string_literal: true

require "suma/twilio"

RSpec.describe Suma::Twilio, :db do
  describe "send_auth_sms" do
    it "sends the message" do
      req = stub_twilio_sms(sid: "SMXYZ").
        with(
          body: {"Body" => "hello", "From" => "17742606953", "To" => "+15554443210"},
          headers: {"Authorization" => "Basic dHdpbGFwaWtleV9zaWQ6dHdpbHNlY3JldA=="},
        )
      result = described_class.send_sms("17742606953", "+15554443210", "hello")
      expect(result).to have_attributes(sid: "SMXYZ")
      expect(req).to have_been_made
    end

    it "raises for REST errors" do
      req = stub_twilio_sms(fixture: "twilio/send_message_invalid_number", status: 400)
      expect do
        described_class.send_sms("17742606953", "+15554443210", "hello")
      end.to raise_error(Twilio::REST::RestError)
      expect(req).to have_been_made
    end

    it "retries once for not-REST errors" do
      req = stub_twilio_sms(sid: "SMXYZ")
      expect(Faraday::Request).to receive(:create).and_raise(Faraday::Error.new("execution expired"))
      expect(Faraday::Request).to receive(:create).and_call_original
      result = described_class.send_sms("17742606953", "+15554443210", "hello")
      expect(result).to have_attributes(sid: "SMXYZ")
      expect(req).to have_been_made
    end

    it "will raise if twilio keeps erroring" do
      expect(Faraday::Request).to receive(:create).twice.and_raise(Faraday::Error.new("execution expired"))
      expect do
        described_class.send_sms("17742606953", "+15554443210", "hello")
      end.to raise_error("execution expired")
    end

    it "retries certain REST errors" do
      req = stub_twilio_sms(fixture: "twilio/send_message_unable_to_create_record", status: 401).times(2)
      expect do
        described_class.send_sms("17742606953", "+15554443210", "hello")
      end.to raise_error(Twilio::REST::RestError)
      expect(req).to have_been_made.times(2)
    end
  end

  describe "send_verification" do
    it "sends the message" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
        with(body: {"Channel" => "sms", "CustomCode" => "123", "To" => "+15554443210", "Locale" => "es"}).
        to_return(status: 200, body: load_fixture_data("twilio/post_verification", raw: true))
      result = described_class.send_verification("+15554443210", code: "123", locale: "es")
      expect(req).to have_been_made
      expect(result).to have_attributes(sid: "VE123")
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
end
