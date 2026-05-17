# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "vernier"

module Suma::Performance
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:performance) do
    setting :request_middleware, false
    setting :slow_query_seconds, 0.06
    setting :log_duplicates, true
    setting :log_slow, true
    setting :vernier_enabled, false
    setting :vernier_key, SecureRandom.hex(20)
  end

  THREAD_KEY = :suma_performance
  VERNIER_PATH = "/_vernier"

  class << self
    # Is performance monitoring active within this context?
    def active? = !Thread.current[THREAD_KEY].nil?

    def skip?(env)
      return true if env["REQUEST_PATH"]&.start_with?("/api/v1/images/")
      return false
    end

    def begin
      Thread.current[THREAD_KEY] = {}
    end

    def end
      Thread.current[THREAD_KEY] = nil
    end

    def span_data
      return Thread.current[THREAD_KEY] ||= {}
    end

    def span_sql_data
      return span_data[:sql] ||= []
    end

    def log_sql(query, duration)
      return unless Suma::Performance.active?
      # Do basic cleaning of the query before logging it
      query = query.strip.delete('"')
      span_sql_data << {query:, duration:}
    end

    # Return process RSS in kb.
    # Ideally we'd use a compile-time condition define but that is too hard to test.
    def memory_kb = Suma.macos? ? memory_kb_macos : memory_kb_linux

    private def memory_kb_macos
      out = Kernel.send(:`, "ps -o rss= -p #{Process.pid}")
      out.to_i
    end

    private def memory_kb_linux
      File.foreach("/proc/self/status") do |line|
        return line.split[1].to_i if line.start_with?("VmRSS:")
      end
      return 0
    end
  end

  class RackMiddleware
    def initialize(app, logger: Suma::Performance.logger)
      @app = app
      @logger = logger
    end

    def call(env)
      return @app.call(env) unless Suma::Performance.request_middleware
      return @app.call(env) if Suma::Performance.skip?(env)
      Suma::Performance.begin
      begin
        @app.call(env)
      ensure
        self.log_perf
        Suma::Performance.end
      end
    end

    private def homogenize_sql(q) = q.gsub(/\d+/, "0")

    def log_perf
      tags = {}

      sql = Suma::Performance.span_sql_data
      # How long did we spend in the database (driver and remote)
      tags[:sql_duration] = sql.sum { |q| q[:duration] }
      ignore_queries = ["COMMIT", "ROLLBACK"]
      # All the non-transaction queries
      queries = []
      # How many transactions did we BEGIN
      xaction_count = 0
      # How many queries were slow?
      slow_query_count = 0
      sql.each do |qh|
        q = qh[:query]
        if q == "BEGIN"
          xaction_count += 1
        elsif ignore_queries.include?(q)
          nil
        else
          queries << q
        end
        slow_query_count += 1 if qh[:duration] > Suma::Performance.slow_query_seconds
      end
      tags[:sql_queries] = queries.count
      tags[:sql_slow_queries] = slow_query_count if slow_query_count.positive?
      tags[:sql_xactions] = xaction_count

      # Find exact duplicates. We should almost never have these.
      exact_dupe_counts = Suma::Enumerable.group_and_count(queries)
      tags[:sql_exact_duplicates] = exact_dupe_counts.values.sum - exact_dupe_counts.count
      # Find similarities by replacing all numbers with 0 and seeing what's left.
      # We'll have these somewhat often, especially for things like translated text.
      homogenized_dupe_counts = Suma::Enumerable.group_and_count(queries.map { |q| homogenize_sql(q) })
      tags[:sql_similar_duplicates] = homogenized_dupe_counts.values.sum - homogenized_dupe_counts.count
      tags[:rss_kb] = Suma::Performance.memory_kb

      @logger.info(:performance, tags)

      # Now go over the individual queries to see if we need to log anything
      logged_queries = Set.new
      sql.each do |qhash|
        query = qhash[:query]
        duration = qhash[:duration]
        if Suma::Performance.log_slow && duration > Suma::Performance.slow_query_seconds
          @logger.info(:slow_query, query:, duration:)
        end

        next unless Suma::Performance.log_duplicates
        duplicate_calls = exact_dupe_counts[query] - 1
        if duplicate_calls.positive? && !logged_queries.include?(query)
          @logger.info(:duplicate_query, query:, extra_calls: duplicate_calls)
          logged_queries << query
        end
        homogenized_query = homogenize_sql(query)
        similar_calls = homogenized_dupe_counts[homogenized_query] - 1 - duplicate_calls
        if similar_calls.positive? && !logged_queries.include?(homogenized_query)
          @logger.info(:similar_query, query:, homogenized_query:, extra_calls: similar_calls)
          logged_queries << homogenized_query
        end
      end
    end
  end

  class VernierRackApp
    HOOKS = [
      :activesupport,
      :memory_usage,
    ].freeze

    attr_reader :hooks, :interval, :allocation_interval, :collector, :tempfile

    def initialize(key:, hooks: HOOKS, interval: 200, allocation_interval: 100, mode: :wall)
      @key = key
      @hooks = hooks
      @interval = interval
      @allocation_interval = allocation_interval
      @mode = mode
      @collector = nil
      @tempfile = nil
    end

    def call(env)
      request = Rack::Request.new(env)
      key = request.GET["key"]
      return Rack::Response.new("invalid key", 401, {}).finish unless key == @key
      start = request.GET.key?("start")
      mode = (request.GET["mode"] || @mode).to_sym
      interval = (request.GET["interval"] || @interval).to_i
      allocation_interval = (request.GET["allocation_interval"] || @allocation_interval).to_i
      stop = request.GET.key?("stop")

      @tempfile = Tempfile.new("vernier", binmode: true)
      if start
        opts = {out: @tempfile}
        if mode == :wall
          opts[:interval] = interval
          opts[:allocation_interval] = allocation_interval
        end
        @collector&.send(:finish) # start writes; we just want to finish collecting
        @collector = Vernier::Collector.new(mode, opts)
        @collector.start
      end
      if stop
        return Rack::Response.new("collector not running", 400, {}).finish if @collector.nil?
        result = @collector.stop
        @collector = nil
        body = result.to_firefox(gzip: true)
        @tempfile.unlink
        @tempfile = nil
        filename = "#{request.path.tr('/', '_')}_#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.vernier.json.gz"
        headers = {
          "Content-Type" => "application/octet-stream",
          "Content-Disposition" => "attachment; filename=\"#{filename}\"",
          "Content-Length" => body.bytesize.to_s,
        }
        return Rack::Response.new(body, 200, headers).finish
      end
      return Rack::Response.new("ok", 200, {}).finish
    end
  end
end

unless Sequel::Database.method_defined?(:_suma_orig_log_duration)
  class Sequel::Database
    alias _suma_orig_log_duration log_duration
    def log_duration(duration, message)
      Suma::Performance.log_sql(message, duration)
      return _suma_orig_log_duration(duration, message)
    end
  end
end
