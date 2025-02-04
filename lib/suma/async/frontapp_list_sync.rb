# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async"
require "suma/frontapp/list_sync"

class Suma::Async::FrontappListSync
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "50 6 * * *"
  splay 5

  def _perform
    return unless Suma::Frontapp.configured?
    return unless Suma::Frontapp.list_sync_enabled
    Suma::Frontapp::ListSync.new(now: Time.now).run
  end
end
