# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/lime"

class Suma::Async::SyncLimeFreeBikeStatusGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * * *"
  splay 0.seconds

  def _perform
    return unless Suma::Lime.configured?
    Suma::Mobility::Gbfs::VendorSync.new(
      client: Suma::Lime.gbfs_http_client,
      vendor: Suma::Lime.mobility_vendor,
      component: Suma::Mobility::Gbfs::FreeBikeStatus.new,
    ).sync_all
  end
end
