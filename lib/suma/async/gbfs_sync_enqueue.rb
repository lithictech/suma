# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::GbfsSyncEnqueue
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * * *"
  splay 0

  def _perform
    now = Time.now
    Suma::Mobility::GbfsFeed::SYNCABLE_COMPONENTS.each do |c|
      Suma::Mobility::GbfsFeed.ready_to_sync(c, now:).each do |feed|
        Suma::Async::GbfsSyncRun.perform_async(feed.id, c.to_s)
      end
    end
  end
end
