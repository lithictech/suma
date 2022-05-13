# frozen_string_literal: true

require "suma/api/system"

RSpec.describe Suma::API::System do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  describe "GET /health" do
    it "returns 200" do
      get "/healthz"
      expect(last_response).to have_status(200)
    end
  end

  describe "GET /statusz" do
    it "returns 200" do
      get "/statusz"
      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(:env, :version, :release, :log_level)
    end
  end

  describe "GET /useragent" do
    it "returns 200 and user-agent object" do
      header "User-Agent",
             "Mozilla/5.0 (iPad; CPU OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15
             (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1"
      get "/useragentz"
      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(:device, :platform, :is_android, :is_ios)
      expect(last_response).to have_json_body.that_includes(
        device: "Safari", platform: "iOS (iPad)", platform_version: "14.7.1", is_android: false, is_ios: true,
      )
    end
  end
end
