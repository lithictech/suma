# frozen_string_literal: true

require "suma/http"

RSpec.describe Suma::Http do
  describe "get" do
    it "calls HTTP GET" do
      req = stub_request(:get, "https://a.b").to_return(status: 200, body: "")
      qreq = stub_request(:get, "https://x.y/?x=1").to_return(status: 200, body: "")
      described_class.get("https://a.b", logger: nil)
      described_class.get("https://x.y", {x: 1}, logger: nil)
      expect(req).to have_been_made
      expect(qreq).to have_been_made
    end
    it "requires a :logger" do
      expect { described_class.get("https://x.y") }.to raise_error(ArgumentError, "must pass :logger keyword")
    end
    it "passes through options and merges headers" do
      req = stub_request(:get, "https://a.b/").
        with(
          headers: {
            "Abc" => "123",
            "Authorization" => "Basic dTpw",
            "User-Agent" => "Suma/unknown-release https://mysuma.org 1970-01-01T00:00:00Z",
          },
        ).
        to_return(status: 200, body: "", headers: {})
      described_class.get(
        "https://a.b",
        logger: nil,
        headers: {"ABC" => "123"},
        basic_auth: {username: "u", password: "p"},
      )
      expect(req).to have_been_made
    end
    it "errors on non-ok" do
      req = stub_request(:get, "https://a.b/").to_return(status: 500, body: "meh")
      expect { described_class.get("https://a.b", logger: nil) }.to raise_error(described_class::Error)
      expect(req).to have_been_made
    end

    it "does not error for 300s if not following redirects" do
      req = stub_request(:get, "https://a.b").to_return(status: 307, headers: {location: "https://x.y"})
      resp = described_class.get("https://a.b", logger: nil, follow_redirects: false)
      expect(req).to have_been_made
      expect(resp).to have_attributes(code: 307)
    end

    it "passes through a block" do
      req = stub_request(:get, "https://a.b").to_return(status: 200, body: "abc")
      t = +""
      described_class.get("https://a.b", logger: nil) do |f|
        t << f
      end
      expect(req).to have_been_made
      expect(t).to eq("abc")
    end
  end
  describe "post" do
    it "calls HTTP POST" do
      req = stub_request(:post, "https://a.b").
        with(body: "{}", headers: {"Content-Type" => "application/json"}).
        to_return(status: 200, body: "")
      qreq = stub_request(:post, "https://x.y").
        with(body: {x: 1}.to_json).
        to_return(status: 200, body: "")
      described_class.post("https://a.b", logger: nil)
      described_class.post("https://x.y", {x: 1}, logger: nil)
      expect(req).to have_been_made
      expect(qreq).to have_been_made
    end
    it "calls HTTP POST with form encoding if object body given with form content type" do
      form = "application/x-www-form-urlencoded"
      req = stub_request(:post, "https://x.y").
        with(body: {"x" => "1"}, headers: {"Content-Type" => form}).
        to_return(status: 200, body: "")
      described_class.post("https://x.y", {x: 1}, headers: {"Content-Type" => form}, logger: nil)
      expect(req).to have_been_made
    end
    it "will not to_json string body" do
      req = stub_request(:post, "https://a.b").
        with(body: "xyz").
        to_return(status: 200, body: "")
      described_class.post("https://a.b", "xyz", logger: nil)
      expect(req).to have_been_made
    end
    it "will not to_json if content type is not json" do
      req = stub_request(:post, "https://a.b").
        with(body: "x=1").
        to_return(status: 200, body: "")
      described_class.post(
        "https://a.b",
        {x: 1},
        headers: {"Content-Type" => "xyz"}, logger: nil,
      )
      expect(req).to have_been_made
    end
    it "requires a :logger" do
      expect { described_class.post("https://x.y") }.to raise_error(ArgumentError, "must pass :logger keyword")
    end
    it "passes through options and merges headers" do
      req = stub_request(:post, "https://a.b/").
        with(
          headers: {
            "Abc" => "123",
            "Content-Type" => "x/y",
            "User-Agent" => "Suma/unknown-release https://mysuma.org 1970-01-01T00:00:00Z",
          },
        ).
        to_return(status: 200, body: "", headers: {})
      described_class.post(
        "https://a.b",
        logger: nil,
        headers: {"ABC" => "123", "Content-Type" => "x/y"},
        basic_auth: {username: "u", password: "p"},
      )
      expect(req).to have_been_made
    end
    it "errors on non-ok" do
      req = stub_request(:post, "https://a.b/").to_return(status: 500, body: "meh")
      expect { described_class.post("https://a.b", logger: nil) }.to raise_error(described_class::Error)
      expect(req).to have_been_made
    end

    it "does not error for 300s if not following redirects" do
      req = stub_request(:post, "https://a.b").to_return(status: 307, headers: {location: "https://x.y"})
      resp = described_class.post("https://a.b", logger: nil, follow_redirects: false)
      expect(req).to have_been_made
      expect(resp).to have_attributes(code: 307)
    end

    it "passes through a block" do
      req = stub_request(:post, "https://a.b").to_return(status: 200, body: "abc")
      t = +""
      described_class.post("https://a.b", logger: nil) do |f|
        t << f
      end
      expect(req).to have_been_made
      expect(t).to eq("abc")
    end

    it "can skip raising" do
      req = stub_request(:post, "https://a.b/").to_return(status: 500, body: "meh")
      expect { described_class.post("https://a.b", logger: nil, skip_error: true) }.to_not raise_error
      expect(req).to have_been_made
    end
  end

  describe "Error" do
    it "is rendered nicely" do
      stub_request(:get, "https://a.b/").
        to_return(status: 500, body: "meh", headers: {"X" => "y"})
      begin
        described_class.get("https://a.b", logger: nil)
      rescue Suma::Http::Error => e
        nil
      end
      expect(e).to_not be_nil
      expect(e.to_s).to eq("HttpError(status: 500, method: GET, uri: https://a.b/?, body: meh)")
    end
    it "sanitizes query params with secret or access" do
      stub_request(:get, "https://api.convertkit.com/v3/subscribers?api_secret=bfsek&page=1").
        to_return(status: 500, body: "meh")
      begin
        described_class.get("https://api.convertkit.com/v3/subscribers?api_secret=bfsek&page=1", logger: nil)
      rescue Suma::Http::Error => e
        nil
      end
      expect(e).to_not be_nil
      expect(e.to_s).to eq(
        "HttpError(status: 500, method: GET, " \
        "uri: https://api.convertkit.com/v3/subscribers?api_secret=.snip.&page=1, body: meh)",
      )
    end
  end

  describe "logging" do
    it "logs structured request information" do
      logger = SemanticLogger["http_spec_logging_test"]
      stub_request(:post, "https://foo/bar").to_return({body: "x"})
      logs = capture_logs_from(logger, formatter: :json) do
        described_class.post("https://foo/bar", {x: 1}, logger:)
      end
      expect(logs.map { |j| JSON.parse(j) }).to contain_exactly(
        include("message" => "httparty_request", "context" => include("http_method" => "POST")),
      )
    end
  end
end
