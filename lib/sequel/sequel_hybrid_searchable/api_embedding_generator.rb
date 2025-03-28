# frozen_string_literal: true

require "open3"

class SequelHybridSearchable::ApiEmbeddingGenerator < SequelHybridSearchable::EmbeddingGenerator
  include Appydays::Loggable

  DEFAULT_MODEL = "all-MiniLM-L6-v2"
  PIP_DEPS = "sentence_transformers==3.4.1"

  attr_reader :model_name, :process

  # Create a new instance.
  # @param model_name [String] Default to +DEFAULT_MODEL+.
  # @param pip_install If true, run pip install before starting Python.
  #   If false, assume the necessary +PIP_DEPS+ are already installed.
  #   These are quite big, so we install them at runtime.
  def initialize(model_name=nil, pip_install: true)
    super()
    @model_name = model_name || DEFAULT_MODEL
    @command_sep = SecureRandom.hex(4)
    @mutex = Thread::Mutex.new
    @pip_install = pip_install
  end

  def get_embedding(text)
    return @mutex.synchronize do
      self._get_embedding(text, retrying: false)
    end
  end

  def _get_embedding(text, retrying:)
    env = {"MODEL_NAME" => @model_name, "COMMAND_SEP" => @command_sep}
    if @stdout.nil?
      if @pip_install
        _, sterr, status = Open3.capture3(env, "pip", "install", PIP_DEPS)
        raise "Unexpected exit status from pip: #{status}, #{sterr}" if status.exitstatus.nonzero?
      end
      # Use popen2 so Python will inherit Ruby stderr, and we can see what it's logging out.
      # @stdin, @stdout, @process = Open3.popen2(env, "python", "-c", PYTHON, "r+")
      @stdin, @stdout, @stderr, @process = Open3.popen3(env, "python", "-c", PYTHON, "r+")
      @stdin.sync = true
      @stdout.sync = true
      self.logger.info("started_python_model_process", python_pid: @process.fetch(:pid))
    end
    text = text.strip
    self.logger.debug("encoding_model_embedding", text:)
    begin
      self._write_stdin(text)
      resp_json = self._read_stdout
    rescue Errno::EPIPE, EOFError => e
      raise e if retrying
      self.logger.warn("python_process_broken", exception_class: e.class.name)
      @stdout = nil
      return self._get_embedding(text, retrying: true)
    end
    resp = JSON.parse(resp_json)
    embedding = resp.fetch("embedding")

    if Suma::RACK_ENV != "production"
      cleaned_sent = text.gsub(/\s/, "")
      cleaned_got = resp.fetch("input").gsub(/\s/, "")
      sent_md5 = Digest::MD5.hexdigest(cleaned_sent)
      got_md5 = Digest::MD5.hexdigest(cleaned_got)
      if sent_md5 != got_md5
        raise "Protocol issue: Sent: (#{sent_md5})\n" \
              "#{cleaned_sent.inspect}\n" \
              "Got: (#{got_md5})\n" \
              "#{cleaned_got.inspect}"
      end
    end
    self.logger.debug("encoded_model_embedding", text:, vector_size: embedding.size)
    return embedding
  end

  def _write_stdin(text)
    self._clear_stderr
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

  def _clear_stderr
    # Make sure we empty stderr, or Python will end up blocking witing for Ruby to read it.
    loop do
      @stderr.read_nonblock(1024)
    end
  rescue IO::EAGAINWaitReadable
    return
  end
end
