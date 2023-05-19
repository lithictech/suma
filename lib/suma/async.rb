# frozen_string_literal: true

require "amigo"
require "redis"
require "appydays/configurable"
require "appydays/loggable"
require "sentry-sidekiq"
require "sidekiq"
require "sidekiq-unique-jobs"

require "suma"

Sidekiq.strict_args!(true)

module Suma::Async
  include Appydays::Configurable
  include Appydays::Loggable
  extend Suma::MethodUtilities

  require "suma/async/job_logger"

  # Registry of all jobs that will be required when the async system is started/run.
  JOBS = [
    "suma/async/automation_trigger_runner",
    "suma/async/emailer",
    "suma/async/ensure_default_member_ledgers_on_create",
    "suma/async/funding_transaction_processor",
    "suma/async/message_dispatched",
    "suma/async/order_confirmation",
    "suma/async/plaid_update_institutions",
    "suma/async/reset_code_create_dispatch",
    "suma/async/sync_lime_free_bike_status_gbfs",
    "suma/async/sync_lime_geofencing_zones_gbfs",
    "suma/async/upsert_frontapp_contact",
  ].freeze

  configurable(:async) do
    # The number of (Float) seconds that should be considered "slow" for a job.
    # Jobs that take longer than this amount of time will be logged
    # at `warn` level.
    setting :slow_job_seconds, 1.0

    setting :sidekiq_redis_url, "redis://localhost:6379/0", key: "REDIS_URL"
    setting :sidekiq_redis_provider, ""
    # For sidekiq web UI. Randomize a default so they will only be useful if set.
    setting :web_username, SecureRandom.hex(8)
    setting :web_password, SecureRandom.hex(8)

    after_configured do
      # Very hard to to test this, so it's not tested.
      url = self.sidekiq_redis_provider.present? ? ENV.fetch(self.sidekiq_redis_provider, nil) : self.sidekiq_redis_url
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

        config.client_middleware do |chain|
          chain.add(SidekiqUniqueJobs::Middleware::Client)
        end
        config.server_middleware do |chain|
          chain.add(SidekiqUniqueJobs::Middleware::Server)
        end

        SidekiqUniqueJobs::Server.configure(config)
      end

      Sidekiq.configure_client do |config|
        config.redis = redis_params
        config.client_middleware do |chain|
          chain.add(SidekiqUniqueJobs::Middleware::Client)
        end
      end

      SidekiqUniqueJobs.configure do |config|
        config.logger = Appydays::Loggable[SidekiqUniqueJobs]
        # This adds a Redis call on the path of unique jobs.
        config.enabled = !Suma.test?
      end
    end
  end

  def self.open_web
    u = URI(Suma.api_url)
    u.user = self.web_username
    u.password = self.web_password
    u.path = "/sidekiq"
    `open #{u}`
  end

  # Set up async for the web/client side of things.
  # This performs common Amigo config,
  # and sets up the routing/auditing jobs.
  # It does not require in the actual jobs,
  # since invoking them is the responsibility of the router.
  def self.setup_web
    self._setup_common
    Amigo.install_amigo_jobs
    return true
  end

  # Set up the worker process.
  # This peforms common Amigo config,
  # sets up the routing/audit jobs (since jobs may publish to other jobs),
  # requires the actual jobs,
  # and starts the cron.
  def self.setup_workers
    self._setup_common
    Amigo.install_amigo_jobs
    self._require_jobs
    Amigo.start_scheduler
    return true
  end

  # Set up for tests.
  # This performs common config and requires the jobs.
  # It does not install the routing/auditing jobs,
  # since those should only be installed at specific times.
  def self.setup_tests
    self._setup_common
    self._require_jobs
    return true
  end

  def self._require_jobs
    JOBS.each { |j| require(j) }
  end

  def self._setup_common
    raise "Async already setup, only call this once" if Amigo.structured_logging
    Amigo.structured_logging = true
    Amigo.log_callback = lambda { |j, lvl, msg, o|
      lg = j ? Appydays::Loggable[j] : Suma::Async::JobLogger.logger
      lg.send(lvl, msg, o)
    }
  end

  # Most cron jobs have the same options needed:
  # No retry, and unique for their class.
  def self.cron_job_options
    return {
      retry: false,
      lock: :until_and_while_executing,
      lock_timeout: nil,
      on_conflict: {
        client: :log,
        server: :log,
      },
      lock_args_method: ->(_args) { [] },
    }
  end
end
