# frozen_string_literal: true

require "amigo"
require "redis"
require "appydays/configurable"
require "appydays/loggable"
require "sentry-sidekiq"
require "sidekiq"

require "suma"

# See https://github.com/mperham/sidekiq/pull/5071
# We serialize models a lot, so this isn't suitable.
Sidekiq.strict_args!(false)

module Suma::Async
  include Appydays::Configurable
  include Appydays::Loggable
  extend Suma::MethodUtilities

  require "suma/async/job_logger"

  # Registry of all jobs that will be required when the async system is started/run.
  JOBS = [
    "suma/async/emailer",
    "suma/async/message_dispatched",
    "suma/async/reset_code_create_dispatch",
  ].freeze

  configurable(:async) do
    # The number of (Float) seconds that should be considered "slow" for a job.
    # Jobs that take longer than this amount of time will be logged
    # at `warn` level.
    setting :slow_job_seconds, 1.0

    setting :sidekiq_redis_url, "redis://localhost:6379/0", key: "REDIS_URL"
    setting :sidekiq_redis_provider, ""

    after_configured do
      # Very hard to to test this, so it's not tested.
      url = self.sidekiq_redis_provider.present? ? ENV[self.sidekiq_redis_provider] : self.sidekiq_redis_url
      redis_params = {url:}
      if url.start_with?("rediss:") && ENV["HEROKU_APP_ID"]
        # rediss: schema is Redis with SSL. They use self-signed certs, so we have to turn off SSL verification.
        # There is not a clear KB on this, you have to piece it together from Heroku and Sidekiq docs.
        redis_params[:ssl_params] = {verify_mode: OpenSSL::SSL::VERIFY_NONE}
      end
      Sidekiq.configure_server do |config|
        config.redis = redis_params
        config.options[:job_logger] = Suma::Async::JobLogger
        # We do NOT want the unstructured default error handler
        config.error_handlers.replace([Suma::Async::JobLogger.method(:error_handler)])
        # We must then replace the otherwise-automatically-added sentry middleware
        config.error_handlers << Sentry::Sidekiq::ErrorHandler.new
        config.death_handlers << Suma::Async::JobLogger.method(:death_handler)
      end

      Sidekiq.configure_client do |config|
        config.redis = redis_params
      end
    end
  end

  def self.require_jobs
    Amigo.structured_logging = true
    Amigo.log_callback = lambda { |j, lvl, msg, o|
      lg = j ? Appydays::Loggable[j] : Suma::Async::JobLogger.logger
      lg.send(lvl, msg, o)
    }
    Amigo.install_amigo_jobs
    JOBS.each { |j| require(j) }
  end

  # Start the scheduler.
  # This should generally be run in the Sidekiq worker process,
  # not a webserver process.
  def self.start_scheduler
    hash = self.scheduled_jobs.each_with_object({}) do |job, memo|
      self.logger.info "Scheduling %s every %p" % [job.name, job.cron_expr]
      memo[job.name] = {
        "class" => job.name,
        "cron" => job.cron_expr,
      }
    end
    load_errs = Sidekiq::Cron::Job.load_from_hash hash
    raise "Errors loading sidekiq-cron jobs: %p" % [load_errs] if load_errs.present?
  end
end
