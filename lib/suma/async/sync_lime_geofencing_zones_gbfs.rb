# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/lime"

class Suma::Async::SyncLimeGeofencingZonesGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  # run at minute 0 past every 12th hour
  cron "0 */12 * * *"

  def _perform
    return unless Suma::Lime.configured?
    Suma::Mobility::Gbfs::VendorSync.new(
      client: Suma::Lime.gbfs_http_client,
      vendor: Suma::Lime.mobility_vendor,
      component: Suma::Mobility::Gbfs::GeofencingZone.new,
    ).sync_all
  end
end
