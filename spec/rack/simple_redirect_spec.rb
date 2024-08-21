# frozen_string_literal: true

require "rack/simple_redirect"

RSpec.describe Rack::SimpleRedirect do
  let(:app) { ->(_env) { [200, {}, "success"] } }

  it "redirects string matches" do
    mw = described_class.new(app, routes: {"/x" => "/a", "/y" => "/b"})
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq([302, {"Location" => "/a"}, []])
    expect(mw.call(Rack::MockRequest.env_for("/w"))).to eq([200, {}, "success"])
  end

  it "redirects regex matches" do
    mw = described_class.new(app, routes: {/.*xyz.*/ => "/a"})
    expect(mw.call(Rack::MockRequest.env_for("/abcxyzdef"))).to eq([302, {"Location" => "/a"}, []])
    expect(mw.call(Rack::MockRequest.env_for("/xy"))).to eq([200, {}, "success"])
  end

  it "redirects callable matches" do
    mw = described_class.new(app, routes: {->(env) { env["PATH_INFO"] == "/x" } => "/a"})
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq([302, {"Location" => "/a"}, []])
    expect(mw.call(Rack::MockRequest.env_for("/xy"))).to eq([200, {}, "success"])
  end

  it "can invoke a value to get the location" do
    mw = described_class.new(app, routes: {"/y" => ->(env) { "#{env['PATH_INFO']}/f" }})
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq([200, {}, "success"])
    expect(mw.call(Rack::MockRequest.env_for("/y"))).to eq([302, {"Location" => "/y/f"}, []])
  end
end
