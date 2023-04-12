# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::SyncLimeFreeBikeStatusGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * * *"
  splay 0.seconds

  def _perform
    Suma::Lime.gbfs_sync_free_bike_status
  end

  Amigo.register_job(self)
end
