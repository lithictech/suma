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
  on_worker_boot do |idx|
    ENV["PUMA_WORKER"] = idx.to_s
    SemanticLogger.reopen if defined?(SemanticLogger)
    Suma::Postgres.model_superclasses.each do |modelclass|
      modelclass.db&.disconnect
    end
    Suma::UploadedFile.blob_database.disconnect
  end
end
