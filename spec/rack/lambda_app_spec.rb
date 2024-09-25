# frozen_string_literal: true

require "rack/lambda_app"

RSpec.describe Rack::LambdaApp do
  let(:env) { Rack::MockRequest.env_for }

  let(:app) { ->(_env) { [200, {}, "success"] } }

  it "proxies to the lambda" do
    lambda_app = described_class.new(->(_env) { [429, {}, "teapot"] }).new(app)
    expect(lambda_app.call(env)).to eq([429, {}, "teapot"])
  end

  it "calls the next app if the lambda returns falsey" do
    lambda_app = described_class.new(->(_env) { false }).new(app)
    expect(lambda_app.call(env)).to eq([200, {}, "success"])
  end
end
