# frozen_string_literal: true

require "suma/signalwire"

RSpec.describe Suma::Signalwire, :db do
  describe "send_sms" do
    it "sends the message" do
      req = stub_signalwire_sms(sid: "SMXYZ").
        with(
          body: {"Body" => "hello", "From" => "+17742606953", "To" => "+15554443210"},
          headers: {"Authorization" => "Basic c3ctdGVzdC1wcm9qZWN0OnN3LXRlc3QtdG9rZW4="},
        )
      result = described_class.send_sms("+17742606953", "+15554443210", "hello")
      expect(result).to have_attributes(sid: "SMXYZ")
      expect(req).to have_been_made
    end

    it "raises for REST errors" do
      req = stub_signalwire_sms(fixture: "signalwire/error_invalid_phone", status: 422)
      expect do
        described_class.send_sms("+17742606953", "+15554443210", "hello")
      end.to raise_error(Twilio::REST::RestError)
      expect(req).to have_been_made
    end

    it "retries once for not-REST errors" do
      req = stub_signalwire_sms(sid: "SMXYZ")
      expect(Faraday::Request).to receive(:create).and_raise(Faraday::Error.new("execution expired"))
      expect(Faraday::Request).to receive(:create).and_call_original
      result = described_class.send_sms("+17742606953", "+15554443210", "hello")
      expect(result).to have_attributes(sid: "SMXYZ")
      expect(req).to have_been_made
    end

    it "will raise if twilio keeps erroring" do
      expect(Faraday::Request).to receive(:create).twice.and_raise(Faraday::Error.new("execution expired"))
      expect do
        described_class.send_sms("+17742606953", "+15554443210", "hello")
      end.to raise_error("execution expired")
    end

    it "retries certain REST errors" do
      req = stub_signalwire_sms(fixture: "signalwire/error_internal", status: 400).times(2)
      expect do
        described_class.send_sms("+17742606953", "+15554443210", "hello")
      end.to raise_error(Twilio::REST::RestError)
      expect(req).to have_been_made.times(2)
    end

    it "errors if not in E164 format" do
      expect { described_class.send_sms("17742606953", "+15554443210", "hello") }.to raise_error(ArgumentError)
      expect { described_class.send_sms("+17742606953", "15554443210", "hello") }.to raise_error(ArgumentError)
    end
  end

  describe "make_rest_request" do
    it "makes a GET request" do
      req = stub_request(:get, "https://sumafaketest.signalwire.com//api/video/rooms?x=1").
        with(
          headers: {
            "Authorization" => "Basic c3ctdGVzdC1wcm9qZWN0OnN3LXRlc3QtdG9rZW4=",
            "Content-Type" => "application/json",
          },
        ).
        to_return(json_response)
      described_class.make_rest_request(:get, "/api/video/rooms", query: {x: 1})
      expect(req).to have_been_made
    end

    it "makes a POST request" do
      req = stub_request(:post, "https://sumafaketest.signalwire.com//api/video/rooms").
        with(body: "{\"x\":1}").
        to_return(json_response)
      described_class.make_rest_request(:post, "/api/video/rooms", body: {x: 1})
      expect(req).to have_been_made
    end
  end
end
