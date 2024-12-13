# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/oye"

class Suma::Async::OyeSyncToMembers
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "23 10 * * *"

  def _perform
    return unless Suma::Oye.configured?
    Suma::Oye.sync_to_members
  end
end
