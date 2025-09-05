# frozen_string_literal: true

require "appydays/loggable"

module SequelHybridSearch
  include Appydays::Loggable

  VERSION = "0.0.1"
  INDEXING_MODES = [:async, :sync, :off].freeze
  INDEXING_DEFAULT_MODE = :async

  class << self
    def indexable_models = @indexable_models ||= []
    def reindex_all = self.indexable_models.sum(&:hybrid_search_reindex_all)

    def indexing_mode = @indexing_mode || INDEXING_DEFAULT_MODE

    def indexing_mode=(v)
      raise ArgumentError, "mode #{v.inspect} must be one of: #{INDEXING_MODES}" unless
        INDEXING_MODES.include?(v)
      @indexing_mode = v
    end

    # Return the global threadpool for :async indexing.
    # Use at most a couple threads; if the work gets backed up,
    # have the caller run it. If the threads die,
    # the text update is lost, so we don't want to let it queue up forever.
    def threadpool
      return @threadpool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads: 1,
        max_threads: 2,
        max_queue: 10,
        fallback_policy: :caller_runs,
      )
    end

    # Set your own threadpool.
    attr_writer :threadpool

    # Embedding generator instance.
    # Must be set before the plugin is used.
    # @return [EmbeddingGenerator]
    attr_accessor :embedding_generator
  end

  class EmbeddingGenerator
    def model_name = raise NotImplementedError
    # Return the embedding vector (array of floats) for the text.
    # @return [Array<Float>]
    def get_embedding(_text) = raise NotImplementedError
  end
end
