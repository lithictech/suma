# frozen_string_literal: true

require "rack/immutable"

RSpec.describe Rack::Immutable do
  let(:app) { ->(_env) { [200, {}, "success"] } }

  it "sets cache-control immutable for requests that match the matcher" do
    mw = described_class.new(app, match: "/x")
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq(
      [200, {"Cache-Control" => "public, max-age=604800, immutable"}, "success"],
    )
  end

  it "does not modify cache-control if request does not match" do
    mw = described_class.new(app, match: "/x")
    expect(mw.call(Rack::MockRequest.env_for("/y"))).to eq([200, {}, "success"])
  end

  it "can match against a string" do
    mw = described_class.new(app, match: "/x")
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq(
      [200, {"Cache-Control" => "public, max-age=604800, immutable"}, "success"],
    )
  end

  it "defaults match to regex matching SHA fingerprints" do
    mw = described_class.new(app)
    expect(mw.call(Rack::MockRequest.env_for("/static/foo.abcd1234.js"))).to eq(
      [200, {"Cache-Control" => "public, max-age=604800, immutable"}, "success"],
    )
    expect(mw.call(Rack::MockRequest.env_for("/static/foo.bar.abcd1234.js"))).to eq(
      [200, {"Cache-Control" => "public, max-age=604800, immutable"}, "success"],
    )
    expect(mw.call(Rack::MockRequest.env_for("/static/foo.js"))).to eq([200, {}, "success"])
    expect(mw.call(Rack::MockRequest.env_for("/static/abcd1234.js"))).to eq([200, {}, "success"])
    expect(mw.call(Rack::MockRequest.env_for("/static/foo.abcd-1234.js"))).to eq([200, {}, "success"])
  end

  it "can match against a callable" do
    mw = described_class.new(app, match: ->(env) { env["PATH_INFO"] == "/xy" })
    expect(mw.call(Rack::MockRequest.env_for("/xy"))).to eq(
      [200, {"Cache-Control" => "public, max-age=604800, immutable"}, "success"],
    )
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq([200, {}, "success"])
  end
end
