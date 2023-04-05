# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::SyncLimeGbfs
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * *"

  def _perform
    Suma::Lime.gbfs_sync_all
  end
end
