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
end
