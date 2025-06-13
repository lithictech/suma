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
end
