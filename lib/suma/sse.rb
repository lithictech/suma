# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"

module Suma::SSE
  include Appydays::Configurable
  include Appydays::Loggable

  ORGANIZATION_MEMBERSHIP_VERIFICATIONS = "organization_membership_verifications"

  class << self
    attr_accessor :publisher_redis
  end

  configurable :sse do
    setting :redis_provider, "REDIS_URL"
    setting :redis_url, ""

    after_configured do
      redis_url = Suma::Redis.fetch_url(self.redis_provider, self.redis_url)
      self.publisher_redis = Redis.new(**Suma::Redis.conn_params(redis_url))
    end
  end

  class << self
    # Publish a payload via Redis.
    # Note that the payload here should be
    def publish(topic, payload, t: Time.now)
      self.publisher_redis.publish(topic, {payload:, t: t.to_f}.to_json)
    end

    def new_subscriber_redis
      redis_url = Suma::Redis.fetch_url(self.redis_provider, self.redis_url)
      return Redis.new(**Suma::Redis.conn_params(redis_url))
    end

    def subscribe(topic)
      redis = self.new_subscriber_redis
      redis.subscribe(topic) do |on|
        on.message do |_channel, data|
          msg = JSON.parse(data)
          yield(msg)
        end
      end
    rescue IOError
      # client disconnected
    ensure
      redis&.close
    end
  end

  class NotFound
    def call(*)
      [404, {"Content-Type" => "text/plain"}, "Not Found"]
    end
  end
end
