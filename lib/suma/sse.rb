# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "redis_client"

module Suma::SSE
  include Appydays::Configurable
  include Appydays::Loggable

  TOKEN_HEADER = "Suma-Events-Token"
  ORGANIZATION_MEMBERSHIP_VERIFICATIONS = "organization_membership_verifications"
  NEXT_EVENT_TIMEOUT = 10

  class << self
    attr_accessor :publisher_redis
  end

  configurable :sse do
    setting :redis_provider, "REDIS_URL"
    setting :redis_url, ""

    after_configured do
      redis_url = Suma::Redis.fetch_url(self.redis_provider, self.redis_url)
      self.publisher_redis = RedisClient.new(**Suma::Redis.conn_params(redis_url))
    end
  end

  class << self
    # The SSE session cookie uniquely identifies a connected client (browser tab)
    # so it does not get it publishes.
    def generate_session_id = SecureRandom.base36(12)
    def current_session_id = Thread.current[:sse_session_id]

    def current_session_id=(id)
      Thread.current[:sse_session_id] = id
    end

    # Publish a payload via Redis.
    # Note that the payload here should be
    def publish(topic, payload, t: Time.now)
      msg = {payload:, t: t.to_f}
      if (sid = self.current_session_id)
        msg[:sid] = sid
      end
      self.publisher_redis.pubsub.call("PUBLISH", topic, msg.to_json)
    end

    def new_subscriber_redis
      redis_url = Suma::Redis.fetch_url(self.redis_provider, self.redis_url)
      return RedisClient.new(**Suma::Redis.conn_params(redis_url))
    end

    def subscribe(topic, session_id: nil)
      redis = self.new_subscriber_redis
      sub = redis.pubsub
      sub.call("SUBSCRIBE", topic)
      loop do
        event = sub.next_event(NEXT_EVENT_TIMEOUT)
        next unless event
        event_action, event_topic, event_data = event
        next unless event_action == "message"
        next unless event_topic == topic
        msg = JSON.parse(event_data)
        msg_sid = msg["sid"]
        # The subscriber should know about the message if:
        # - We don't have a subscriber
        # - The message was published by an anonymous subscriber
        # - The message was published by another subscriber
        subscriber_cares = session_id.nil? ||
          msg_sid.nil? ||
          session_id != msg_sid
        yield(msg) if subscriber_cares
      end
    rescue IOError
      # client disconnected
    ensure
      redis&.close
    end
  end

  class NotFound
    def call(*)
      [404, {Rack::CONTENT_TYPE => "text/plain"}, "Not Found"]
    end
  end
end

require_relative "sse/auth"
