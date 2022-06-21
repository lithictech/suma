# frozen_string_literal: true

require "rack/lambda_app"

RSpec.describe Rack::LambdaApp do
  let(:env) { Rack::MockRequest.env_for }

  let(:app) { ->(_env) { [200, {}, "success"] } }

  subject { described_class.new(->(_env) { [429, {}, "teapot"] }).new(app) }

  it "proxies to the lambda" do
    expect(subject.call(env)).to eq([429, {}, "teapot"])
  end
end
