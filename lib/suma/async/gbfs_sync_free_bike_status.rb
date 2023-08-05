# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::GbfsSyncFreeBikeStatus
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * * *"
  splay 0

  def _perform
    Suma::Mobility::Gbfs::Syncable.registry.each do |_key, syncable|
      syncable.component_vendor_syncs(Suma::Mobility::Gbfs::FreeBikeStatus.new).each(&:sync_all)
    end
  end
end
