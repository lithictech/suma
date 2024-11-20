# frozen_string_literal: true

require "suma/enumerable"

module Suma::Performance
  include Appydays::Configurable

  configurable(:performance) do
    setting :request_middleware, false
    setting :slow_query_seconds, 0.06
    setting :log_duplicates, true
    setting :log_slow, true
  end

  THREAD_KEY = :suma_performance

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
  end

  class RackMiddleware
    def initialize(app, logger:)
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
end

class Sequel::Database
  alias _suma_orig_log_duration log_duration
  def log_duration(duration, message)
    Suma::Performance.log_sql(message, duration)
    return _suma_orig_log_duration(duration, message)
  end
end
