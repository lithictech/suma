# frozen_string_literal: true

require "suma/twilio"

RSpec.describe Suma::Twilio, :db do
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

  describe "check_verification" do
    it "checks the verification code" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/VerificationCheck").
        with(body: {"To" => "+15554443210", "Code" => "123456"}).
        to_return(status: 200, body: load_fixture_data("twilio/post_verification_check", raw: true))
      result = described_class.check_verification("+15554443210", code: "123456")
      expect(req).to have_been_made
      expect(result).to have_attributes(sid: "VE123", valid: true)
    end
  end
end
