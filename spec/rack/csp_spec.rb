# frozen_string_literal: true

require "rack/csp"

# rubocop:disable Layout/LineLength
RSpec.describe Rack::Csp do
  let(:app) { ->(_env) { [200, {}, "success"] } }
  def req = Rack::MockRequest.env_for("/")

  def csp(mw)
    resp = mw.call(req)
    expect(resp[0]).to eq(200)
    return resp[1].fetch("Content-Security-Policy")
  end

  it "includes a basic Content-Security-Policy header" do
    mw = described_class.new(app)
    expect(csp(mw)).to eq("default-src 'self'")
  end

  it "can use an array for safe values" do
    mw = described_class.new(app, policy: {safe: ["'self'", "x.y", nil, "'keyword'"]})
    expect(csp(mw)).to eq("default-src 'self' x.y 'keyword'; img-src 'self' x.y 'keyword'; script-src 'self' x.y 'keyword'")
  end

  it "can use a custom header name" do
    mw = described_class.new(app, header: "Content-Security-Policy-Report-Only")
    resp = mw.call(req)
    expect(resp[0]).to eq(200)
    csp = resp[1].fetch("Content-Security-Policy-Report-Only")
    expect(csp).to eq("default-src 'self'")
  end

  it "can use a policy string" do
    mw = described_class.new(app, policy: "hi")
    expect(csp(mw)).to eq("hi")
  end

  it "can use a policy object" do
    mw = described_class.new(app, policy: described_class::Policy.new)
    expect(csp(mw)).to eq("default-src 'self'; img-src 'self'; script-src 'self'")

    mw = described_class.new(app, policy: described_class::Policy.new(img_data: true))
    expect(csp(mw)).to eq("default-src 'self'; img-src 'self' data:; script-src 'self'")

    mw = described_class.new(
      app,
      policy: described_class::Policy.new(
        safe: "mysuma.org",
        inline_scripts: ['alert("hi");'],
        script_hashes: ["e4trTQ78v1I1FExl6EETmBlLXlO713o0nRoAfKgded0="],
        img_data: true,
        parts: {
          "font-src" => "fonts.gstatic.com",
        },
      ),
    )
    expect(csp(mw)).to eq("default-src mysuma.org; img-src mysuma.org data:; script-src mysuma.org 'sha256-e4trTQ78v1I1FExl6EETmBlLXlO713o0nRoAfKgded0=' 'sha256-I+aF1T6GxfsV/3ftFVsOQOwl0AH9185nnmbxwNt269E='; font-src fonts.gstatic.com")
  end

  it "uses parts to set and override auto-generated policy parts" do
    mw = described_class.new(
      app,
      policy: described_class::Policy.new(
        parts: {"img-src" => "hello"},
      ),
    )
    expect(csp(mw)).to eq("default-src 'self'; img-src hello; script-src 'self'")
  end

  it "will template the safe fields into the string <SAFE> in parts" do
    mw = described_class.new(
      app,
      policy: described_class::Policy.new(
        parts: {"img-src" => "hi <SAFE> bye"},
      ),
    )
    expect(csp(mw)).to eq("default-src 'self'; img-src hi 'self' bye; script-src 'self'")
  end

  it "does not mutate the default safe string" do
    mw = described_class.new(
      app,
      policy: described_class::Policy.new(
        safe: ["'self'", "x.y"],
        img_data: true,
      ),
    )
    expect(csp(mw)).to eq("default-src 'self' x.y; img-src 'self' x.y data:; script-src 'self' x.y")
  end

  it "can use a policy hash, where string keys are used as additional policy fields" do
    mw = described_class.new(
      app,
      policy: {
        safe: "mysuma.org",
        inline_scripts: ['alert("hi");'],
        script_hashes: ["e4trTQ78v1I1FExl6EETmBlLXlO713o0nRoAfKgded0="],
        img_data: true,
        "font-src" => "fonts.gstatic.com",
      },
    )
    expect(csp(mw)).to eq("default-src mysuma.org; img-src mysuma.org data:; script-src mysuma.org 'sha256-e4trTQ78v1I1FExl6EETmBlLXlO713o0nRoAfKgded0=' 'sha256-I+aF1T6GxfsV/3ftFVsOQOwl0AH9185nnmbxwNt269E='; font-src fonts.gstatic.com")
  end

  it "prefers conflicting policy parts" do
    mw = described_class.new(
      app,
      policy: {
        parts: {
          "img-src" => "images",
        },
        "font-src" => "fonts",
        "img-src" => "imagesouter",
      },
    )
    expect(csp(mw)).to eq("default-src 'self'; img-src images; script-src 'self'; font-src fonts")
  end

  describe "extract_script_hashes" do
    it "returns base64 hashes of elements matching the xpath (<script data-csp='ok'>)" do
      html = <<~HTML
        <html>
          <script>alert('no attr')</script>
          <script data-csp="ok">alert('ok')</script>
          <script data-csp="ok">alert('ok2')</script>
          <script data-csp="">alert('not ok')</script>
          <div data-csp="ok">not a script</div>
        </html>
      HTML
      expect(described_class.extract_script_hashes(html)).to eq(
        ["GhSELej6D4No8Cu4c6BlA7SQooAXc4iM9HQ5s9uW7Gw=", "xi7KGU6bmso/fXSy1Ch4jpjavgXhfiFMPTIOoCPA5EQ="],
      )
    end
  end
end
# rubocop:enable Layout/LineLength
