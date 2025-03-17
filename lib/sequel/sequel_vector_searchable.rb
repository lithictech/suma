# frozen_string_literal: true

require "open3"

module SequelVectorSearchable
  VERSION = "0.0.1"
  INDEXING_MODES = [:async, :sync, :off].freeze
  INDEXING_DEFAULT_MODE = :async

  class << self
    def searchable_models = @searchable_models ||= []
    def reindex_all = self.searchable_models.sum(&:vector_search_reindex_all)

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

    # Embeddings generator instance.
    # Set this to use another generator, like for an API.
    # @return [EmbeddingsGenerator]
    def embeddings_generator = @embeddings_generator ||= SubprocSentenceTransformerGenerator.new

    # Set your own generator.
    attr_writer :embeddings_generator
  end

  class EmbeddingsGenerator
    # Return the embeddings vector (array of floats) for the text.
    # @return [Array<Float>]
    def get_embeddings(_text) = raise NotImplementedError
  end

  # Use a model from the sentence-transformers Python module,
  # and call it through a subprocess.
  # Note that PyCall was tried but could not be used, because we couldn't get it to run in a Ractor,
  # or without the GVL.
  #
  # NOTE: Different models require different vector dimension size in the database,
  # so you will need to migrate and re-index.
  #
  # Some model ideas to try out:
  #
  # Model                       | Dims   | Size   | Use Cases                       | Memory & CPU Efficiency
  # all-MiniLM-L6-v2            | 384    | ~100MB | Text search, clustering, QA     | Very efficient
  # distilbert-base-uncased     | 768    | ~300MB | Semantic search, classification | Moderate
  # paraphrase-MiniLM-L3-v2     | 384    | ~45MB  | Lightweight search, similarity  | Extremely efficient
  # facebook/distilroberta-base | 768    | ~250MB | Text classification, NLI        | Moderate
  # t5-small                    | 512    | ~250MB | Summarization, classification   | Moderate
  # distilgpt2                  | 768    | ~250MB | Text generation, embeddings     | Moderate
  class SubprocSentenceTransformerGenerator < EmbeddingsGenerator
    DEFAULT_MODEL = "all-MiniLM-L6-v2"

    def initialize(name=nil)
      super()
      @name = name || DEFAULT_MODEL
    end

    def get_embeddings(text)
      env = {"MODEL_NAME" => @name}
      @stdin, @stdout, @wait_thr = Open3.popen2e(env, "python", "-c", PYTHON, "r+") if @stdout.nil?
      at_exit do
        @wait_thr.kill
      end
      @stdin.puts "#{text}\n"
      @stdin.flush
      embed_json = @stdout.readline.strip
      embeds = JSON.parse(embed_json)
      return embeds
    end

    PYTHON = <<~PYTHON
      import json
      import os
      import sentence_transformers
      import sys
      import torch

      model_name = os.getenv("MODEL_NAME")
      if not model_name:
          raise "Must set MODEL_NAME env var"

      model = sentence_transformers.SentenceTransformer(model_name, device="cpu")
      model = model.to(dtype=torch.float16)


      def encode(txt):
          return model.encode(txt).tolist()


      while True:
          try:
              inp = sys.stdin.readline().strip()
              enc = encode(inp)
              sys.stdout.write(json.dumps(enc))
              sys.stdout.write("\\n")
              sys.stdout.flush()
          except (BrokenPipeError, IOError):
              sys.exit(0)
    PYTHON
  end
end
