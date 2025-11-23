# frozen_string_literal: true

require "rack/utm_capture"

RSpec.describe Rack::UtmCapture do
  before(:each) do
    allow(Time).to receive(:now).and_return Time.parse("2020-01-01T00:00:00Z")
  end

  it "saves utm parameters into cookies" do
    app = ->(_env) { [200, {}, []] }
    mw = described_class.new(app)
    headers = {
      "Set-Cookie" => [
        "utm_source=x; path=/; expires=Fri, 31 Jan 2020 00:00:00 GMT; SameSite=Lax",
        "utm_campaign=y; path=/; expires=Fri, 31 Jan 2020 00:00:00 GMT; SameSite=Lax",
      ],
    }
    expect(mw.call(Rack::MockRequest.env_for("/a?utm_source=x&utm_campaign=y"))).to eq([200, headers, []])
  end

  it "appends to set-cookie (string)" do
    app = ->(_env) { [200, {"Set-Cookie" => "z"}, []] }
    mw = described_class.new(app)
    headers = {
      "Set-Cookie" => ["z", "utm_source=x; path=/; expires=Fri, 31 Jan 2020 00:00:00 GMT; SameSite=Lax"],
    }
    expect(mw.call(Rack::MockRequest.env_for("/a?utm_source=x"))).to eq([200, headers, []])
  end

  it "appends to set-cookie (array)" do
    app = ->(_env) { [200, {"Set-Cookie" => ["p", "q"]}, []] }
    mw = described_class.new(app)
    headers = {
      "Set-Cookie" => ["p", "q", "utm_source=x; path=/; expires=Fri, 31 Jan 2020 00:00:00 GMT; SameSite=Lax"],
    }
    expect(mw.call(Rack::MockRequest.env_for("/a?utm_source=x"))).to eq([200, headers, []])
  end

  it "does not stomp existing cookies" do
    app = ->(_env) { [200, {}, []] }
    mw = described_class.new(app)
    headers = {
      "Set-Cookie" => ["utm_campaign=y; path=/; expires=Fri, 31 Jan 2020 00:00:00 GMT; SameSite=Lax"],
    }
    req = Rack::MockRequest.env_for("/a?utm_source=x&utm_campaign=y")
    req["HTTP_COOKIE"] = "utm_source=x; utm_terms=z"
    expect(mw.call(req)).to eq([200, headers, []])
  end

  it "does not add the header if there are no utm params" do
    app = ->(_env) { [200, {}, []] }
    mw = described_class.new(app)
    expect(mw.call(Rack::MockRequest.env_for("/a"))).to eq([200, {}, []])
  end
end
