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
      if url.start_with?("rediss:")
        # rediss: schema is Redis with SSL. redis-client needs ssl: true explicitly.
        params[:ssl] = true
        # Hereoku uses self-signed certs, so we have to turn off SSL verification.
        # There is not a clear KB on this, you have to piece it together from Heroku and Sidekiq docs.
        # This is still required as of August 2025.
        (params[:ssl_params] = {verify_mode: OpenSSL::SSL::VERIFY_NONE}) if ENV["HEROKU_APP_ID"]
      end
      params.merge!(kw)
      return params
    end

    # Figure out the redis url to use. If +url_arg+ is present, use it.
    # It should be effectivley `ENV['REDIS_URL']`.
    # Otherwise, use `ENV[provider]` if provider is present.
    # This should be like `ENV['REDIS_PROVIDER']`.
    def fetch_url(provider, url_arg)
      return url_arg if url_arg.present?
      return "" if provider.blank?
      return ENV.fetch(provider, "")
    end

    def create_pool(provider, url_arg)
      url = fetch_url(provider, url_arg)
      redis_config = RedisClient.config(**self.conn_params(url, reconnect_attempts: 1))
      return redis_config.new_pool(
        timeout: Suma::Postgres::Model.pool_timeout,
        size: Suma::Postgres::Model.max_connections,
      )
    end
  end

  configurable(:redis) do
    setting :cache_url, ""
    setting :cache_url_provider, "REDIS_URL"

    after_configured do
      self.cache = self.create_pool(self.cache_url_provider, self.cache_url)
    end
  end

  # @param [Array<String>] parts
  # @return [String]
  def self.cache_key(parts)
    tail = parts.join("/")
    return "cache/#{tail}"
  end
end
