# frozen_string_literal: true

require "rack/attack"
require "suma/redis"

module Suma::RackAttack
  include Appydays::Configurable

  configurable(:rate_limiting) do
    # True to enable rate limiting, false to disable it.
    # If enabled, but store and provider are not set, use a memory store.
    setting :enabled, false
    # The url for the Redis store.
    # Can also use a redis_url_provider if sharing a Redis server.
    setting :redis_url, ""
    # Environment variable, like 'REDIS_URL', to pull the redis_url from.
    # Allows sharing a Redis server between multiple parts of the app.
    setting :redis_provider, ""

    after_configured do
      Rack::Attack.enabled = self.enabled
      redis_url = Suma::Redis.fetch_url(self.redis_provider, self.redis_url)
      Rack::Attack.cache.store =
        if redis_url.present?
          ActiveSupport::Cache::RedisCacheStore.new(**Suma::Redis.conn_params(redis_url))
        elsif self.enabled
          ActiveSupport::Cache::MemoryStore.new
        end
    end
  end

  Rack::Attack.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = Time.now.to_i
    retry_after = match_data[:period] - (now % match_data[:period])
    headers = {"Content-Type" => "application/json", "Retry-After" => retry_after.to_s}
    # Pass the retry-after value in the body as well as the header.
    body = Suma::Service.error_body(
      429,
      "Rate limited",
      code: "too_many_requests",
      more: {retry_after: retry_after.to_s},
    )
    return [429, headers, [body.to_json]]
  end

  def self.throttle_many(base_key, *settings, &)
    settings.each_with_index do |setting, i|
      Rack::Attack.throttle("#{base_key}/#{i + 1}", **setting, &)
    end
  end
end
