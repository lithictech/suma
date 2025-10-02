# frozen_string_literal: true

require "amigo/autoscaler"
require "amigo/autoscaler/checkers/chain"
require "amigo/autoscaler/checkers/puma_pool_usage"
require "amigo/autoscaler/checkers/sidekiq"
require "amigo/autoscaler/checkers/web_latency"
require "amigo/autoscaler/handlers/chain"
require "amigo/autoscaler/handlers/heroku"
require "amigo/autoscaler/handlers/log"
require "amigo/autoscaler/handlers/sentry"

require "suma/heroku"
require "suma/redis"

module Suma::Autoscaler
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:autoscaler) do
    setting :sentry_alert_interval, 180

    setting :worker_enabled, false
    # The log handler is always used.
    # If 'sentry' is in the string, use the Sentry handler.
    # If 'heroku' is in the string, use the Sentry handler.
    setting :worker_handlers, "sentry"
    setting :worker_latency_threshold, 10.0
    setting :worker_alert_interval, 180
    setting :worker_poll_interval, 30
    setting :worker_max_additional_workers, 2
    setting :worker_latency_restored_threshold, 0
    setting :worker_hostname_regex, /^web\.1$/, convert: ->(s) { Regexp.new(s) }

    setting :web_enabled, false
    # The log handler is always used.
    # If 'sentry' is in the string, use the Sentry handler.
    # If 'heroku' is in the string, use the Sentry handler.
    setting :web_handlers, "sentry"
    # Over 5s, start scaling. Under 5s, we can start scaling down.
    setting :web_latency_threshold, 4.0
    # Scale if our pool is over 85% used.
    setting :web_usage_threshold, 0.85
    setting :web_alert_interval, 20
    setting :web_poll_interval, 15
    setting :web_max_additional_workers, 2
    setting :web_hostname_regex, /^web\.2$/, convert: ->(s) { Regexp.new(s) }
  end

  class << self
    def build_worker
      return build_common(
        handlers: self.worker_handlers,
        logger: self.logger,
        max_additional_workers: self.worker_max_additional_workers,
        formation: "worker",
        sentry_message: "Some queues have a high latency",
        log_message: "high_latency_queues",
        checker: Amigo::Autoscaler::Checkers::Sidekiq.new,
        poll_interval: self.worker_poll_interval,
        latency_threshold: self.worker_latency_threshold,
        hostname_regex: self.worker_hostname_regex,
        alert_interval: self.worker_alert_interval,
        latency_restored_threshold: self.worker_latency_restored_threshold,
        namespace: "amigo/autoscaler",
      )
    end

    def build_web
      return build_common(
        handlers: self.web_handlers,
        logger: self.logger,
        max_additional_workers: self.web_max_additional_workers,
        formation: "web",
        sentry_message: "Web requests have a high latency",
        log_message: "high_latency_requests",
        checker: Amigo::Autoscaler::Checkers::Chain.new(
          [
            Amigo::Autoscaler::Checkers::WebLatency.new(redis: Suma::Redis.cache),
            self.puma_pool_usage_checker,
          ],
        ),
        poll_interval: self.web_poll_interval,
        latency_threshold: self.web_latency_threshold,
        usage_threshold: self.web_usage_threshold,
        hostname_regex: self.web_hostname_regex,
        alert_interval: self.web_alert_interval,
        namespace: "amigo/web_autoscaler",
      )
    end

    def puma_pool_usage_checker
      @puma_pool_usage_checker ||= Amigo::Autoscaler::Checkers::PumaPoolUsage.new(redis: Suma::Redis.cache)
      return @puma_pool_usage_checker
    end

    def build_common(
      handlers:,
      logger:,
      max_additional_workers:,
      formation:,
      log_message:,
      sentry_message:,
      checker:,
      **
    )
      chain = [
        Amigo::Autoscaler::Handlers::Log.new(
          message: log_message,
          log: ->(level, msg, kw={}) { logger.send(level, msg, kw) },
        ),
      ]
      if handlers&.include?("sentry")
        chain << Amigo::Autoscaler::Handlers::Sentry.new(
          message: sentry_message,
          interval: self.sentry_alert_interval,
        )
      end
      if handlers&.include?("heroku")
        chain << Amigo::Autoscaler::Handlers::Heroku.new(
          client: Suma::Heroku.client,
          formation:,
          max_additional_workers:,
          app_id_or_app_name: Suma::Heroku.app_name,
        )
      end
      return Amigo::Autoscaler.new(
        **,
        on_unhandled_exception: ->(e) { Sentry.capture_exception(e) },
        handler: Amigo::Autoscaler::Handlers::Chain.new(chain),
        checker:,
      )
    end
  end
end
