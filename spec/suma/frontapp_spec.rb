# frozen_string_literal: true

require "suma/frontapp"

RSpec.describe Suma::Frontapp do
  it "converts values to API ids" do
    expect(described_class.to_api_id("cnv", 1234)).to eq("cnv_ya")
    expect(described_class.to_api_id("cnv", "1234")).to eq("cnv_ya")
    expect(described_class.to_api_id("cnv", "cnv_1234")).to eq("cnv_1234")
    expect(described_class.to_api_id("cnv", "cnv_abc")).to eq("cnv_abc")
    expect(described_class.to_api_id("cnv", "")).to eq("")
    expect(described_class.to_api_id("cnv", nil)).to be_nil
    expect { described_class.to_api_id("cnv", "msg_123") }.to raise_exception(ArgumentError)
  end

  describe "make_http_request" do
    it "makes an http request" do
      req = stub_request(:post, "https://api2.frontapp.com/foo").
        with(
          body: '{"x":1}',
          headers: {
            "Accept" => "*/*",
            "Authorization" => "Bearer get-from-front-add-to-env",
            "Content-Type" => "application/json",
            "Y" => "z",
          },
        ).
        to_return(json_response({z: 1}))
      r = Suma::Frontapp.make_http_request(:post, "/foo", body: {x: 1}, headers: {"Y" => "z"})
      expect(req).to have_been_made
      expect(r.parsed_response).to eq({"z" => 1})
    end
  end
end
