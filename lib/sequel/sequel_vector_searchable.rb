# frozen_string_literal: true

require "concurrent"
require "pycall"

module SequelVectorSearchable
  VERSION = "0.0.1"

  class << self
    def searchable_models = @searchable_models ||= []
  end

  module Indexing
    MODES = [:async, :sync, :off].freeze
    DEFAULT_MODE = :async

    class << self
      def mode = @mode || DEFAULT_MODE

      def mode=(v)
        raise ArgumentError, "mode #{v.inspect} must be one of: #{MODES}" unless
          MODES.include?(v)
        @mode = v
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

      def reindex_all
        return SequelVectorSearchable.searchable_models.sum(&:vector_search_reindex_all)
      end
    end
  end

  module Embeddings
    DEFAULT_MODEL = "all-MiniLM-L6-v2"

    class << self
      # The name of the model.
      # NOTE: Changing the model name will require a different vector dimension size in the database,
      # so you will need to migrate and re-index.
      #
      # Some model ideas to try out:
      #
      # Model                       | Dims   | Size   | Use Cases                       | Memory & CPU Efficiency
      # distilbert-base-uncased     | 768    | ~300MB | Semantic search, classification | Moderate
      # all-MiniLM-L6-v2            | 384    | ~100MB | Text search, clustering, QA     | Very efficient
      # paraphrase-MiniLM-L3-v2     | 384    | ~45MB  | Lightweight search, similarity  | Extremely efficient
      # facebook/distilroberta-base | 768    | ~250MB | Text classification, NLI        | Moderate
      # t5-small                    | 512    | ~250MB | Summarization, classification   | Moderate
      # distilgpt2                  | 768    | ~250MB | Text generation, embeddings     | Moderate
      attr_accessor :model

      # Start setting up the model. This can take several seconds, so this code can be called on server startup.
      # Calls to +#embeddings+ will wait for setup to finish.
      def setup
        return if @model
        raise "must be called on the main thread" unless Thread.current == Thread.main
        self.model ||= DEFAULT_MODEL
        @setup_mutex = Thread::Mutex.new
        # Should use PyCall.without_gvl, but it isn't working locally
        # Thread.new do
        @setup_mutex.synchronize do
          sentence_transformer = PyCall.import_module("sentence_transformers")
          torch = PyCall.import_module("torch")
          model = sentence_transformer.SentenceTransformer.new(self.model, device: "cpu")
          @model = model.to(dtype: torch.float16)
        end
        # end
      end

      def get(text)
        self.setup
        return @setup_mutex.synchronize do
          @model.encode(text).tolist
        end
      end
    end
  end
end
