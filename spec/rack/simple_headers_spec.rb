# frozen_string_literal: true

require "rack/simple_headers"

RSpec.describe Rack::SimpleHeaders do
  it "force-sets headers" do
    app = ->(_env) { [200, {"Abc" => "Spam", "Xyz" => "Bar"}, []] }
    mw = described_class.new(app, {"Abc" => "Foo"})
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq([200, {"Abc" => "Foo", "Xyz" => "Bar"}, []])
  end

  it "can set default headers" do
    app = ->(_env) { [200, {"Abc" => "Spam", "Xyz" => "Bar"}, []] }
    mw = described_class.new(app, {}, defaults: {"Abc" => "Foo"})
    expect(mw.call(Rack::MockRequest.env_for("/x"))).to eq([200, {"Abc" => "Spam", "Xyz" => "Bar"}, []])
  end
end
