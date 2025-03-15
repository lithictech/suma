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
  end

  describe "lime" do
    it "returns nil for station information and status" do
      req = stub_request(:get, "https://data.lime.bike/api/partners/v2/gbfs_transit/free_bike_status.json").
        to_return(json_response({x: 1}))
      expect(Suma::Lime.gbfs_http_client.fetch_free_bike_status).to eq({"x" => 1})
      expect(req).to have_been_made
      expect(Suma::Lime.gbfs_http_client.fetch_station_information).to be_nil
      expect(Suma::Lime.gbfs_http_client.fetch_station_status).to be_nil
    end
  end

  describe "lyft" do
    it "fetches" do
      req = stub_request(:get, "https://gbfs.lyft.com/gbfs/2.3/pdx/en/station_information.json").
        to_return(json_response({x: 1}))

      expect(Suma::Lyft.gbfs_http_client.fetch_station_information).to eq({"x" => 1})
      expect(req).to have_been_made
    end
  end
end
