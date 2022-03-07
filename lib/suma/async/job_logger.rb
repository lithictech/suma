# frozen_string_literal: true

require "appydays/loggable/sidekiq_job_logger"

require "suma/async" unless defined? Suma::Async

class Suma::Async::JobLogger < Appydays::Loggable::SidekiqJobLogger
  protected def slow_job_seconds
    return Suma::Async.slow_job_seconds
  end
end
