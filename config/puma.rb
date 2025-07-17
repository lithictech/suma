# frozen_string_literal: true

lib = File.expand_path("lib", "#{__dir__}/..")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "appydays/dotenviable"
Appydays::Dotenviable.load

raise "No port defined?" unless ENV["PORT"]
port ENV.fetch("PORT", nil)

workers_count = Integer(ENV.fetch("WEB_CONCURRENCY", 2))
workers workers_count
threads_count = Integer(ENV["RAILS_MAX_THREADS"] || 4) # We must use threads, even locally, due to Server Sent Events
threads threads_count, threads_count

preload_app!

require "suma"
Suma.load_app
require "suma/async/autoscaler"
Suma::Async::Autoscaler.start

if workers_count.positive?
  before_fork do
    Suma::Postgres.model_superclasses.map(&:db).each(&:disconnect)
    Suma::UploadedFile.blob_database.disconnect
    Suma::Webhookdb.connection.disconnect
  end

  on_worker_boot do |idx|
    ENV["PUMA_WORKER"] = idx.to_s
    SemanticLogger.reopen if defined?(SemanticLogger)
    # We have to recreate the DB for some reason or we get segfaults in cluster mode.
    # I'm not sure why. Probably some adapter state that is left over.
    # See https://github.com/jeremyevans/sequel/discussions/2318
    Suma::Postgres.model_superclasses.select do |c|
      c.respond_to?(:run_after_configured_hooks)
    end.each(&:run_after_configured_hooks)
  end
end