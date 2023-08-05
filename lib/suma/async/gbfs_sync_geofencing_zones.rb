# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::GbfsSyncGeofencingZones
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  # run at minute 0 past every 12th hour
  cron "0 */12 * * *"

  def _perform
    Suma::Mobility::Gbfs::Syncable.registry.each do |_key, syncable|
      syncable.component_vendor_syncs(Suma::Mobility::Gbfs::GeofencingZone.new).each(&:sync_all)
    end
  end
end
