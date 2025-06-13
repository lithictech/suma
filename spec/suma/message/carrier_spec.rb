# frozen_string_literal: true

require "suma/message"

RSpec.describe Suma::Message::Carrier, :db do
  describe described_class::TwilioVerify do
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
    end
  end

  describe described_class::Signalwire do
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
  end
end
