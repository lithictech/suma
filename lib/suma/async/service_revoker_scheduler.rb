# frozen_string_literal: true

require "amigo/scheduled_job"

require "suma/program/service_revoker"

# Run the service revoker on an interval.
class Suma::Async::ServiceRevokerScheduler
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "4,34 * * * *" # Twice an hour
  splay 60.seconds

  def _perform
    Suma::Program::ServiceRevoker.run
  end
end
