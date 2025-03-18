# frozen_string_literal: true

require "open3"
require "appydays/loggable"

module SequelVectorSearchable
  include Appydays::Loggable

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
    def model_name = raise NotImplementedError
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
    include Appydays::Loggable

    DEFAULT_MODEL = "all-MiniLM-L6-v2"

    attr_reader :model_name, :process

    def initialize(model_name=nil)
      super()
      @model_name = model_name || DEFAULT_MODEL
      @command_sep = SecureRandom.hex(4)
      @mutex = Thread::Mutex.new
    end

    def get_embeddings(text)
      return @mutex.synchronize do
        self._get_embeddings(text, retrying: false)
      end
    end

    def _get_embeddings(text, retrying:)
      env = {"MODEL_NAME" => @model_name, "COMMAND_SEP" => @command_sep}
      if @stdout.nil?
        # @stdin, @stdout, @process = Open3.popen2(env, "python", "-c", PYTHON, "r+")
        @stdin, @stdout, @stderr, @process = Open3.popen3(env, "python", "-c", PYTHON, "r+")
        @stdin.sync = true
        @stdout.sync = true
        self.logger.info("started_python_model_process", python_pid: @process.fetch(:pid))
      end
      text = text.strip
      self.logger.debug("encoding_model_embeddings", text:)
      begin
        self._write_stdin(text)
        resp_json = self._read_stdout
      rescue Errno::EPIPE, EOFError => e
        raise e if retrying
        self.logger.warn("python_process_broken", exception_class: e.class.name)
        @stdout = nil
        return self._get_embeddings(text, retrying: true)
      end
      resp = JSON.parse(resp_json)
      embeddings = resp.fetch("embeddings")

      if Suma::RACK_ENV != "production"
        cleaned_sent = text.gsub(/\s/, "")
        cleaned_got = resp.fetch("input").gsub(/\s/, "")
        sent_md5 = Digest::MD5.hexdigest(cleaned_sent)
        got_md5 = Digest::MD5.hexdigest(cleaned_got)
        if sent_md5 != got_md5
          msg = "Protocol issue: Sent: (#{sent_md5})\n" \
                "#{cleaned_sent.inspect}\n" \
                "Got: (#{got_md5})\n" \
                "#{cleaned_got.inspect}"
          raise msg
        end
      end
      self.logger.debug("encoded_model_embeddings", text:, vector_size: embeddings.size)
      return embeddings
    end

    def _write_stdin(text)
      @stdin.puts text
      @stdin.puts "\n#{@command_sep}\n"
      @stdin.flush
    end

    def _read_stdout
      accum = []
      loop do
        line = @stdout.readline.strip
        return accum.join("\n") if line == @command_sep
        accum << line
      end
    end

    PYTHON = File.read(__FILE__.gsub(/\.rb$/, ".py"))
  end
end
