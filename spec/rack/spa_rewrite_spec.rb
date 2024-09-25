# frozen_string_literal: true

require "timecop"

require "rack/spa_rewrite"

RSpec.describe Rack::SpaRewrite do
  around(:each) do |ex|
    Timecop.freeze("2022-11-30T00:00:00Z") do
      ex.run
    end
  end

  let(:app) { ->(_env) { [200, {}, "success"] } }
  let(:index_path) { Suma::SpecHelpers::TEST_DATA_DIR + "rack/spa/index.html" }

  let(:modtimehttp) { "Sun, 30 Oct 2022 00:00:00 GMT" }
  before(:each) do
    FileUtils.touch index_path, mtime: Time.parse("2022-10-30T00:00:00Z")
  end

  describe "getting the index mod time" do
    it "gets the file mod time" do
      mw = described_class.new(app, index_path:, html_only: true)
      expect(mw).to have_attributes(index_mtime: match_time("2022-10-30T00:00:00Z"))
    end

    it "uses 0 if the index file does not exist" do
      mw = described_class.new(app, index_path: "/dev/does-not-exist/null", html_only: true)
      expect(mw).to have_attributes(index_mtime: match_time(0))
    end
  end

  it "handles GETs" do
    mw = described_class.new(app, index_path:, html_only: false)
    expect(mw.call(Rack::MockRequest.env_for("/w", method: :get))).to eq(
      [
        200,
        {"Content-Length" => 13, "Content-Type" => "text/html", "Last-Modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
        ["<html></html>"],
      ],
    )
  end

  it "handles HEADs" do
    mw = described_class.new(app, index_path:, html_only: false)
    expect(mw.call(Rack::MockRequest.env_for("/w", method: :head))).to match_array(
      [
        200,
        {"Content-Length" => 13, "Content-Type" => "text/html", "Last-Modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
        be_empty,
      ],
    )
  end

  it "handles OPTIONs" do
    mw = described_class.new(app, index_path:, html_only: false)
    expect(mw.call(Rack::MockRequest.env_for("/w", method: :options))).to eq(
      [200, {"Allow" => "GET, HEAD, OPTIONS", "Content-Length" => "0"}, []],
    )
  end

  it "returns 304 if if-none-match check succeeds" do
    mw = described_class.new(app, index_path:, html_only: false)
    env = Rack::MockRequest.env_for("/w", method: :get, "HTTP_IF_MODIFIED_SINCE" => modtimehttp)
    expect(mw.call(env)).to eq([304, {}, []])
  end

  it "returns 200 if if-none-matches check fails" do
    mw = described_class.new(app, index_path:, html_only: false)
    env = Rack::MockRequest.env_for("/w", method: :get, "HTTP_IF_MODIFIED_SINCE" => Time.now.httpdate)
    expect(mw.call(env)).to eq(
      [
        200,
        {"Content-Length" => 13, "Content-Type" => "text/html", "Last-Modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
        ["<html></html>"],
      ],
    )
  end

  describe "with html_only true" do
    let(:mw) { described_class.new(app, index_path:, html_only: true) }

    it "calls the underlying app if the request does not end with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w", method: :get))).to eq([200, {}, "success"])
    end

    it "returns the file if the request ends with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w.html", method: :get))).to eq(
        [
          200,
          {"Content-Length" => 13, "Content-Type" => "text/html", "Last-Modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
          ["<html></html>"],
        ],
      )
    end
  end

  describe "with html_only false" do
    let(:mw) { described_class.new(app, index_path:, html_only: false) }

    it "returns the file if the request does not end with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w", method: :get))).to eq(
        [
          200,
          {"Content-Length" => 13, "Content-Type" => "text/html", "Last-Modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
          ["<html></html>"],
        ],
      )
    end

    it "returns the file if the request ends with html" do
      expect(mw.call(Rack::MockRequest.env_for("/w.html", method: :get))).to eq(
        [
          200,
          {"Content-Length" => 13, "Content-Type" => "text/html", "Last-Modified" => "Sun, 30 Oct 2022 00:00:00 GMT"},
          ["<html></html>"],
        ],
      )
    end
  end
end
