# frozen_string_literal: true

require "rack/service_worker_allowed"

RSpec.describe Rack::ServiceWorkerAllowed do
  let(:env) { Rack::MockRequest.env_for }

  let(:app) { ->(_env) { [200, {}, "success"] } }

  it "adds the allowed header if the Service-Worker header is passed" do
    env = {"HTTP_SERVICE_WORKER" => ""}
    swapp = described_class.new(app, scope: "foo")
    expect(swapp.call(env)).to eq([200, {"Service-Worker-Allowed" => "foo"}, "success"])
  end

  it "does not add a header if Service-Worker header is not passed" do
    env = {}
    swapp = described_class.new(app, scope: "foo")
    expect(swapp.call(env)).to eq([200, {}, "success"])
  end
end
