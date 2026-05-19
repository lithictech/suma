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
end

require "suma/performance/rack_middleware"
require "suma/performance/vernier"

unless Sequel::Database.method_defined?(:_suma_orig_log_duration)
  class Sequel::Database
    alias _suma_orig_log_duration log_duration
    def log_duration(duration, message)
      Suma::Performance.log_sql(message, duration)
      return _suma_orig_log_duration(duration, message)
    end
  end
end
