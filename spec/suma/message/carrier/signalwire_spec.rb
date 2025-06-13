# frozen_string_literal: true

RSpec.describe Suma::Message::Carrier::Signalwire do
  let(:carrier) { described_class.new }

  describe "fetch_message_details" do
    it "fetches the verification from Signalwire" do
      req = stub_request(:get, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages/123.json").
        to_return(json_response(load_fixture_data("signalwire/send_message")))

      d = carrier.fetch_message_details("123")
      expect(req).to have_been_made
      expect(d).to include(
        "account_sid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "date_created" => be_a(Time),
      )
    end
  end

  describe "send!" do
    let(:params) { {override_from: nil, to: "+15554443210", body: "hello"} }

    it "sends message via Signalwire" do
      req = stub_signalwire_sms(sid: "SMXYZ").
        with(body: {"Body" => "hello", "From" => "+15554443333", "To" => "+15554443210"})
      result = described_class.new.send!(**params)
      expect(result).to eq("SMXYZ")
      expect(req).to have_been_made
    end

    it "can override the from number" do
      req = stub_signalwire_sms(sid: "SMXYZ").
        with(body: {"Body" => "hello", "From" => "+19998887777", "To" => "+15554443210"})
      result = described_class.new.send!(**params, override_from: "19998887777")
      expect(result).to eq("SMXYZ")
      expect(req).to have_been_made
    end

    it "raises undeliverable if the phone number is invalid" do
      req = stub_signalwire_sms(fixture: "signalwire/error_invalid_phone", status: 400)
      expect do
        described_class.new.send!(**params)
      end.to raise_error(Suma::Message::UndeliverableRecipient, /signalwire_invalid_phone_number/)
      expect(req).to have_been_made
    end

    it "raises signalwire errors" do
      req = stub_signalwire_sms(body: "error", status: 500)
      expect do
        described_class.new.send!(**params)
      end.to raise_error(Twilio::REST::RestError, /HTTP 500/)
      expect(req).to have_been_made
    end
  end
end
