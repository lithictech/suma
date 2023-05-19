# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::SyncLimeGeofencingZonesGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  # run at minute 0 past every 12th hour
  cron "0 */12 * * *"

  def _perform
    Suma::Mobility::Gbfs::GeofencingZone.new(client: self.gbfs_http_client, vendor: self.scooter_vendor).sync_all
  end
end
