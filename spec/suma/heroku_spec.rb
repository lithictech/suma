# frozen_string_literal: true

require "suma/heroku"

RSpec.describe Suma::Heroku, reset_configuration: Suma::Heroku do
  describe "::client" do
    it "creates a client with the configured settings" do
      described_class.oauth_id = "x"
      described_class.oauth_token = "x"
      expect(described_class.client).to be_a(PlatformAPI::Client)
    end

    it "errors if unconfigured" do
      expect { described_class.client }.to raise_error(/SUMA_HEROKU_OAUTH_TOKEN not set/)
    end
  end
end
