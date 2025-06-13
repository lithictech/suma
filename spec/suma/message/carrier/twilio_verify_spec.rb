# frozen_string_literal: true

RSpec.describe Suma::Message::Carrier::TwilioVerify do
  let(:carrier) { described_class.new }

  describe "verification ID parsing" do
    it "parses the first part of the ID" do
      expect(carrier.decode_message_id("123-1")).to eq("123")
      expect(carrier.encode_message_id("123", "1")).to eq("123-1")
      expect(carrier.decode_message_id("123")).to eq("123")
    end
  end

  describe "fetch_message_details" do
    it "fetches the verification from Twilio" do
      req = stub_request(:get, "https://verify.twilio.com/v2/Services/VA555test/Verifications/123").
        to_return(json_response(load_fixture_data("twilio/post_verification")))

      d = carrier.fetch_message_details("123")
      expect(req).to have_been_made
      expect(d).to include(
        "account_sid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "date_created" => be_a(Time),
      )
    end

    it "returns a clear response if the verification 404s" do
      body = {
        code: 20_404,
        message: "The requested resource blah was not found",
        more_info: "https://www.twilio.com/docs/errors/20404",
        status: 404,
      }
      req = stub_request(:get, "https://verify.twilio.com/v2/Services/VA555test/Verifications/123").
        to_return(json_response(body, status: 404))

      d = carrier.fetch_message_details("123")
      expect(req).to have_been_made
      expect(d).to include(
        status: "unknown",
        message: match(/Only pending verifications can be fetched/),
      )
    end
  end

  describe "send!" do
    let(:params) { {to: "+15554443210", code: "12345", locale: "es", channel: "sms"} }

    it "sends verification messages via twilio verify" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
        with(body: {"Channel" => "sms", "CustomCode" => "12345", "To" => "+15554443210", "Locale" => "es"}).
        to_return(status: 200, body: load_fixture_data("twilio/post_verification", raw: true))
      result = described_class.new.send!(**params)
      expect(result).to eq("VE123-1")
      expect(req).to have_been_made
    end

    it "raises undeliverable if the phone number is invalid" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
        to_return(status: 400, body: load_fixture_data("twilio/error_invalid_phone", raw: true))
      expect do
        described_class.new.send!(**params)
      end.to raise_error(Suma::Message::UndeliverableRecipient, /twilio_invalid_phone_number/)
      expect(req).to have_been_made
    end

    it "raises other twilio errors" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
        to_return(status: 500, body: "error")
      expect do
        described_class.new.send!(**params)
      end.to raise_error(Twilio::REST::RestError, /HTTP 500/)
      expect(req).to have_been_made
    end
  end
end
