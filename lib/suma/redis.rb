# frozen_string_literal: true

require "appydays/configurable"
require "redis_client"
require "suma/postgres/model"

module Suma::Redis
  include Appydays::Configurable

  class << self
    attr_accessor :cache

    def conn_params(url, **kw)
      params = {url:}
      if url.start_with?("rediss:") && ENV["HEROKU_APP_ID"]
        # rediss: schema is Redis with SSL. They use self-signed certs, so we have to turn off SSL verification.
        # There is not a clear KB on this, you have to piece it together from Heroku and Sidekiq docs.
        params[:ssl_params] = {verify_mode: OpenSSL::SSL::VERIFY_NONE}
      end
      params.merge!(kw)
      return params
    end
  end

  configurable(:redis) do
    setting :cache_url, "redis://localhost:22007/0"
    setting :cache_url_provider, "REDIS_URL"

    after_configured do
      url = ENV.fetch(self.cache_url_provider, self.cache_url)
      redis_config = RedisClient.config(**self.conn_params(url, reconnect_attempts: 1))
      self.cache = redis_config.new_pool(
        timeout: Suma::Postgres::Model.pool_timeout,
        size: Suma::Postgres::Model.max_connections,
      )
    end
  end

  # @param [Array<String>] parts
  # @return [String]
  def self.cache_key(parts)
    tail = parts.join("/")
    return "cache/#{tail}"
  end
end
