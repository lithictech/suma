# frozen_string_literal: true

require "suma/message"

RSpec.describe Suma::Message::Carrier, :db do

  describe Suma::Message::Carrier::TwilioVerify do
    describe "verification ID parsing" do
      it "parses the first part of the ID" do
        xport = described_class.new
        expect(xport.decode_message_id("123-1")).to eq("123")
        expect(xport.encode_message_id("123", "1")).to eq("123-1")
      end
    end
  end
end
