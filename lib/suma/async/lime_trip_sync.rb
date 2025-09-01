# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/lime/sync_trips_from_email"

class Suma::Async::LimeTripSync
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * *"
  splay 5.seconds

  def _perform
    Suma::Lime::SyncTripsFromEmail.new.run
  end
end
