# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/oye"

class Suma::Async::SyncOyeContactSmsPreferences
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  # run at minute 0 past every 24th hour
  cron "0 */24 * * *"

  def _perform
    return unless Suma::Oye.configured?
    Suma::Oye.sync_contact_sms_preferences
  end
end
