# frozen_string_literal: true

require "suma/mobility/gbfs"
require "suma/mobility/gbfs/http_client"

RSpec.describe Suma::Mobility::Gbfs::HttpClient do
  let(:client) { described_class.new(api_host: "https://mysuma.org", auth_token: "tok") }

  describe "fetch_json" do
    it "fetches" do
      req = stub_request(:get, "https://mysuma.org/foo.json").
        with(headers: {"Authorization" => "Bearer tok"}).
        to_return(json_response({x: 1}))

      got = client.fetch_json("foo")
      expect(got).to eq({"x" => 1})
      expect(req).to have_been_made
    end

    it "handles a nil token (no authorization header)" do
      client = described_class.new(api_host: "https://mysuma.org", auth_token: nil)
      req = stub_request(:get, "https://mysuma.org/foo.json").
        # Not sure how to test *not* sending a header.
        to_return(json_response({x: 1}))
      got = client.fetch_json("foo")
      expect(got).to eq({"x" => 1})
      expect(req).to have_been_made
    end

    it "returns nil for a 404" do
      req = stub_request(:get, "https://mysuma.org/foo.json").
        to_return(status: 404)

      expect(client.fetch_json("foo")).to be_nil
      expect(req).to have_been_made
    end

    it "raises other http errors" do
      req = stub_request(:get, "https://mysuma.org/foo.json").
        to_return(status: 403)

      expect { client.fetch_json("foo") }.to raise_error(Suma::Http::Error)
    end
  end
end
