# frozen_string_literal: true

require "url_shortener"
require "url_shortener/rack_app"
require "url_shortener/spec_helpers"
require "rspec/matchers/fail_matchers"

RSpec.describe UrlShortener do
  before(:all) do
    @conn = Sequel.connect(ENV.fetch("DATABASE_URL"))
  end
  let(:conn) { @conn }
  let(:table) { :url_shortener }
  let(:root) { "https://mysite.com" }
  let(:not_found_url) { "https://not-found.com" }
  let(:shortener) { described_class.new(conn:, table:, root:, not_found_url:) }

  before(:each) do
    shortener.dataset.delete
  end
  after(:each) do
    shortener.dataset.delete
  end

  it "uses the current time as the base of the random id" do
    Timecop.freeze(100) do
      id1 = described_class.gen_short_id(2)
      id2 = described_class.gen_short_id(2)
      expect(id1[...6]).to eq(id2[...6])
      expect(id1[6..]).to_not eq(id2[6..])
      Timecop.freeze(200) do
        id3 = described_class.gen_short_id(2)
        expect(id3[...6]).to_not eq(id1[...6])
      end
    end
  end

  it "can generate and resolve shortened urls" do
    expect(described_class).to receive(:gen_short_id).and_return("abc123")
    expect(shortener.shorten("https://x.y.z")).to have_attributes(short_id: "abc123", short_url: "https://mysite.com/abc123")
    expect(shortener.resolve_short_id("abc123")).to eq("https://x.y.z")
    expect(shortener.resolve_short_url("https://mysite.com/abc123")).to eq("https://x.y.z")
  end

  it "can resolve short urls with trailing slashes and query params" do
    expect(described_class).to receive(:gen_short_id).and_return("abc123")
    shortener.shorten("https://x.y.z")
    expect(shortener.resolve_short_url("https://mysite.com/abc123")).to eq("https://x.y.z")
    expect(shortener.resolve_short_url("https://mysite.com/abc123/")).to eq("https://x.y.z")
    expect(shortener.resolve_short_url("https://mysite.com/abc123/?x=1")).to eq("https://x.y.z")
    expect(shortener.resolve_short_url(URI("https://mysite.com/abc123/?x=1"))).to eq("https://x.y.z")
  end

  it "cannot resolve unknown ids" do
    expect(shortener.resolve_short_id("abc123")).to be_nil
  end

  it "will not generate duplicates" do
    expect(described_class).to receive(:gen_short_id).
      exactly(4).times.
      and_return(
        "123",
        "123",
        "123",
        "456",
      )
    expect(shortener.shorten("https://1")).to have_attributes(short_id: "123")
    expect(shortener.shorten("https://2")).to have_attributes(short_id: "456")
  end

  it "errors if no unique id can be generated" do
    expect(described_class).to receive(:gen_short_id).
      exactly(described_class::MAX_UNIQUE_ID_ATTEMPTS).times.
      and_return("123")
    shortener.shorten("https://abc")
    expect { shortener.shorten("https://abc") }.to raise_error(described_class::NoIdAvailable)
  end

  describe "update" do
    it "updates with an explicit short id" do
      s = shortener.shorten("z")
      shortener.update(s.id, short_id: "shorty")
      expect(shortener.dataset[id: s.id]).to include(short_id: "shorty")
    end

    it "generates a new id if blank" do
      s = shortener.shorten("z")
      expect(s.short_id).to match(/[a-z0-9]+/)
      old = s.short_id
      s2 = shortener.update(s.id, short_id: " ")
      expect(s2.short_id).to match(/[a-z0-9]+/)
      expect(s2.short_id).to_not eq(old)
    end

    it "trims spaces" do
      s = shortener.shorten("z")
      shortener.update(s.id, short_id: " x ", url: " y ")
      expect(shortener.dataset[id: s.id]).to include(short_id: "x", url: "y")
    end

    it "sets the timestamp" do
      t = Time.at(Time.now.to_i)
      s = shortener.shorten("url1", now: t)
      expect(shortener.dataset[id: s.id]).to include(inserted_at: t)
      t2 = t + 20
      shortener.update(s.id, short_id: "x", url: "url2", now: t2)
      expect(shortener.dataset[short_id: "x"]).to include(short_id: "x", url: "url2", inserted_at: t2)
    end
  end

  describe "RackApp" do
    include Rack::Test::Methods

    def app
      @app ||= UrlShortener::RackApp.new(shortener)
    end

    it "405s on unexpected methods" do
      patch "/abc"

      expect(last_response).to have_attributes(status: 405)
    end

    it "redirects on matched urls" do
      new_url = shortener.shorten("https://x.y.z").short_url
      new_url.delete_prefix!(root)

      get new_url

      expect(last_response).to have_attributes(status: 302)
      expect(last_response.headers).to include("Location" => "https://x.y.z")
      expect(last_response.body).to eq(
        "<html><body>This content has moved to <a href=\"https://x.y.z\">https://x.y.z</a></body></html>",
      )
    end

    it "redirects to not found url on unmatched urls" do
      get "/123"

      expect(last_response).to have_attributes(status: 302)
      expect(last_response.headers).to include("Location" => "https://not-found.com")
    end
  end

  describe "be_a_shortlink_to" do
    include RSpec::Matchers::FailMatchers

    let(:url_shortener) { shortener }
    it "passes if the actual value is a shortlink to the given value" do
      raw_url = "https://me"
      # Make sure empty works
      expect("x").to_not be_a_shortlink_to(raw_url)
      expect(described_class).to receive(:gen_short_id).and_return("abc123")
      shorty = shortener.shorten(raw_url)
      expect(shorty.short_id).to be_a_shortlink_to(raw_url)
      expect(shorty.short_url).to be_a_shortlink_to(raw_url)

      expect do
        expect(nil).to be_a_shortlink_to(raw_url)
      end.to fail_with("No shortened URL found for nil")

      expect do
        expect(shorty.short_id + "1").to be_a_shortlink_to(raw_url)
      end.to fail_with("No shortened URL found for \"abc1231\"")

      expect do
        expect(shorty.short_url + "1").to be_a_shortlink_to(raw_url)
      end.to fail_with("No shortened URL found for \"https://mysite.com/abc1231\"")

      expect do
        expect("").to be_a_shortlink_to(raw_url)
      end.to fail_with("No shortened URL found for \"\"")
    end
  end
end
