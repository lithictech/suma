# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/lyft"

class Suma::Async::SyncLyftFreeBikeStatusGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * * *"
  splay 0.seconds

  def _perform
    return unless Suma::Lyft.sync_enabled
    Suma::Mobility::Gbfs::VendorSync.new(
      client: Suma::Lyft.gbfs_http_client,
      vendor: Suma::Lyft.mobility_vendor,
      component: Suma::Mobility::Gbfs::FreeBikeStatus.new,
    ).sync_all
  end
end
