# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/lime/sync_trips_from_report"

class Suma::Async::LimeTripSync
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * *"
  splay 5.seconds

  def _perform
    Suma::Lime::SyncTripsFromReport.new.run if Suma::Lime.trip_report_sync_enabled
  end
end
