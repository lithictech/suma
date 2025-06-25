# frozen_string_literal: true

require "amigo"
require "appydays/configurable"
require "appydays/loggable"
require "sentry-sidekiq"
require "sidekiq"
require "sidekiq-unique-jobs"

require "suma"
require "suma/redis"

Sidekiq.strict_args!(true)

module Suma::Async
  include Appydays::Configurable
  include Appydays::Loggable
  extend Suma::MethodUtilities

  require "suma/async/job_logger"
  require "suma/async/job_utils"

  # Registry of all jobs that will be required when the async system is started/run.
  JOBS = [
    "suma/async/analytics_dispatch",
    "suma/async/anon_proxy_destroyed_member_contact_cleanup",
    "suma/async/deprecated_jobs",
    "suma/async/emailer",
    "suma/async/forward_messages",
    "suma/async/frontapp_upsert_contact",
    "suma/async/funding_transaction_processor",
    "suma/async/gbfs_sync_enqueue",
    "suma/async/gbfs_sync_run",
    "suma/async/hybrid_search_reindex",
    "suma/async/lyft_pass_trip_sync",
    "suma/async/marketing_list_sync",
    "suma/async/marketing_sms_broadcast_dispatch",
    "suma/async/member_default_relations",
    "suma/async/member_onboarding_verified_dispatch",
    "suma/async/message_dispatched",
    "suma/async/offering_schedule_fulfillment",
    "suma/async/order_confirmation",
    "suma/async/payout_transaction_processor",
    "suma/async/plaid_update_institutions",
    "suma/async/process_anon_proxy_inbound_webhookdb_relays",
    "suma/async/reset_code_create_dispatch",
    "suma/async/reset_code_update_twilio",
    "suma/async/signalwire_process_optouts",
    "suma/async/stripe_refunds_backfiller",
  ].freeze

  configurable(:async) do
    # The number of (Float) seconds that should be considered "slow" for a job.
    # Jobs that take longer than this amount of time will be logged
    # at `warn` level.
    setting :slow_job_seconds, 1.0

    # Smaller values here can be useful where we combine polling and webhooks,
    # like AnonProxy, but we don't have webhooks available for a certain environment.
    # For example, using 10 here in development avoids having to wait 30 seconds
    # to look for inbound emails.
    setting :cron_poll_interval, 30

    setting :sidekiq_redis_url, "", key: "REDIS_URL"
    setting :sidekiq_redis_provider, ""
    # For sidekiq web UI. Randomize a default so they will only be useful if set.
    setting :web_username, SecureRandom.hex(8)
    setting :web_password, SecureRandom.hex(8)

    after_configured do
      # Very hard to to test this, so it's not tested.
      url = Suma::Redis.fetch_url(self.sidekiq_redis_provider, self.sidekiq_redis_url)
      redis_params = Suma::Redis.conn_params(url)
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
    Sidekiq::Options[:cron_poll_interval] = self.cron_poll_interval
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
