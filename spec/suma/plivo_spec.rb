# frozen_string_literal: true

require "suma/plivo"

RSpec.describe Suma::Plivo, :db do
  describe "request" do
    it "makes the request" do
      req = stub_request(:post, "https://api.plivo.com/v1/Account/MA_FAKE_A4NTUWNMEYZW/Message/").
        with(
          body: {src: "13334445555", dst: "144455566666", text: "msg", url: "https://example.com"}.to_json,
          headers: {
            "Authorization" => "Basic TUFfRkFLRV9BNE5UVVdOTUVZWlc6ZmFrZS1hdXRoLXRva2Vu",
            "Content-Type" => "application/json",
          },
        ).
        to_return(fixture_response("plivo/message_send"))
      resp = Suma::Plivo.send_sms("13334445555", "144455566666", "msg")
      expect(resp.parsed_response).to include("api_id", "message_uuid")
      expect(req).to have_been_made
    end
  end
end
