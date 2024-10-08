# frozen_string_literal: true

require "suma/redis"

RSpec.describe Suma::Redis do
  describe "#conn_params" do
    it "returns keyword arguments" do
      params = described_class.conn_params("redis://localhost:1234/0", reconnect_attempts: 1, timeout: 1.0)
      expect(params).to include(url: "redis://localhost:1234/0", reconnect_attempts: 1, timeout: 1.0)
    end

    it "returns ssl_params when using heroku redis" do
      ssl_schema_url = "rediss://"
      none_ssl_schema_url = "redis://"

      expect(described_class.conn_params(none_ssl_schema_url)).to_not include(:ssl_params)
      expect(described_class.conn_params(ssl_schema_url)).to_not include(:ssl_params)
      ENV["HEROKU_APP_ID"] = "a1b2bc"
      expect(described_class.conn_params(ssl_schema_url)).to include(ssl_params: {verify_mode: 0})
      expect(described_class.conn_params(none_ssl_schema_url)).to_not include(:ssl_params)
    ensure
      ENV.delete("HEROKU_APP_ID")
    end
  end

  describe "cache_key" do
    it "returns a key" do
      expect(Suma::Redis.cache_key(["x", "y"])).to eq("cache/x/y")
    end
  end
end
