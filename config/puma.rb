# frozen_string_literal: true

# workers Integer(ENV['WEB_CONCURRENCY'] || 1)
# threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 2)
# threads threads_count, threads_count

lib = File.expand_path("lib", "#{__dir__}/..")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "appydays/dotenviable"
Appydays::Dotenviable.load

raise "No port defined?" unless ENV["PORT"]
port ENV.fetch("PORT", nil)

preload_app!

require "suma/async/autoscaler"
Suma::Async::Autoscaler.start

Thread.new do
  # Preload the embeddings generator so it's available on the first call.
  require "sequel/sequel_hybrid_searchable"
  SequelHybridSearchable.embedding_generator.get_embedding("")
end

on_worker_boot do
  SemanticLogger.reopen if defined?(SemanticLogger)
  if defined?(Suma::Postgres)
    Suma::Postgres.each_model_superclass do |modelclass|
      modelclass.db&.disconnect
    end
    Suma::UploadedFile.blob_database.disconnect
  end
end
