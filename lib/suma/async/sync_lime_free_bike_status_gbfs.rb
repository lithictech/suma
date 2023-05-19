# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::SyncLimeFreeBikeStatusGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * * *"
  splay 0.seconds

  def _perform
    Suma::Mobility::Gbfs::FreeBikeStatus.new(client: self.gbfs_http_client, vendor: self.scooter_vendor).sync_all
  end
end
