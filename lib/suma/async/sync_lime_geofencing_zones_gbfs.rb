# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::SyncLimeGeofencingZonesGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  # run at minute 0 past every 12th hour
  cron "0 */12 * * *"

  def _perform
    Suma::Lime.gbfs_sync_geofencing_zones
  end

  Amigo.register_job(self)
end
