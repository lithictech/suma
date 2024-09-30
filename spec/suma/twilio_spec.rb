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

  describe "update_verification" do
    it "sends the update" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications/VE123").
        with(body: {"Status" => "approved"}).
        to_return(status: 200, body: load_fixture_data("twilio/post_verification", raw: true))
      result = described_class.update_verification("VE123", status: "approved")
      expect(req).to have_been_made
      expect(result).to have_attributes(sid: "VE123")
    end

    it "raises twilio errors other than code 20404" do
      req404 = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications/VE404").
        with(body: {"Status" => "approved"}).
        # twilios API error codes are passed in the body
        to_return(status: 404, body: {code: 20_404}.to_json)
      req500 = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications/VE500").
        with(body: {"Status" => "approved"}).
        to_return(status: 500)

      expect do
        described_class.update_verification("VE404", status: "approved")
      end.to_not raise_error
      expect(req404).to have_been_made
      expect do
        described_class.update_verification("VE500", status: "approved")
      end.to raise_error(Twilio::REST::TwilioError, /500/)
      expect(req500).to have_been_made
    end
  end
end
