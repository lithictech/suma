# frozen_string_literal: true

lib = File.expand_path("lib", "#{__dir__}/..")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

ENV["PROC_MODE"] = "puma"

require "appydays/dotenviable"
Appydays::Dotenviable.load

raise "No port defined?" unless ENV["PORT"]
port ENV.fetch("PORT", nil)

workers_count = Integer(ENV.fetch("WEB_CONCURRENCY", "2"))
workers workers_count
# We must use threads, even locally, due to Server Sent Events
threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", "4"))
threads threads_count, threads_count

preload_app!

require "barnes"
require "suma"
Suma.load_app

require "suma/autoscaler"
require "suma/i18n/static_string_rebuilder"

if Suma::Autoscaler.web_enabled
  amigo_autoscaler_interval Suma::Autoscaler.web_poll_interval
  amigo_puma_pool_usage_checker Suma::Autoscaler.puma_pool_usage_checker
  plugin :amigo
end

def run_singleton_threads
  Suma::I18n::StaticStringRebuilder.instance.start_watcher unless Suma::I18n.static_string_watcher_disabled
  Suma::Autoscaler.build_worker.start if Suma::Autoscaler.worker_enabled
  Suma::Autoscaler.build_web.start if Suma::Autoscaler.web_enabled
end

# Load the appropriate code based on if we're running clustered or not.
# If we are not clustered, just start Barnes.
# If we are, then start Barnes before the fork, and reconnect files and database conns after the fork.
if workers_count.positive?
  before_fork do
    Barnes.start
    Suma::Postgres.model_superclasses.map(&:db).each(&:disconnect)
    Suma::UploadedFile.blob_database.disconnect
    Suma::Webhookdb.connection.disconnect
  end

  on_worker_boot do |idx|
    ENV["PUMA_WORKER"] = idx.to_s
    run_singleton_threads if idx.zero?
    SemanticLogger.reopen if defined?(SemanticLogger)
  end
else
  Barnes.start
  run_singleton_threads
end
