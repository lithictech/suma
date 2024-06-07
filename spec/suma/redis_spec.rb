# frozen_string_literal: true

require "suma/redis"

RSpec.describe Suma::Redis do
  describe "#conn_params" do
    it "returns keyword arguments" do
      params = described_class.conn_params("redis://localhost:1234/0", reconnect_attempts: 1, timeout: 1.0)
      puts params.inspect
      expect(params[:url]).to eq("redis://localhost:1234/0")
      expect(params[:reconnect_attempts]).to eq(1)
      expect(params[:timeout]).to eq(1.0)
    end

    it "returns ssl_params when using heroku redis" do
      ssl_schema_url = "rediss://"
      none_ssl_schema_url = "redis://"

      expect(described_class.conn_params(none_ssl_schema_url)[:ssl_params]).to be_nil
      expect(described_class.conn_params(ssl_schema_url)[:ssl_params]).to be_nil
      ENV["HEROKU_APP_ID"] = "a1b2bc"
      expect(described_class.conn_params(ssl_schema_url)[:ssl_params]).to include(:verify_mode)
      expect(described_class.conn_params(none_ssl_schema_url)[:ssl_params]).to be_nil
    ensure
      ENV.delete("HEROKU_APP_ID")
    end
  end
end
