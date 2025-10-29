# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async"

class Suma::Async::StaticStringsTrim
  extend Amigo::ScheduledJob
  include Suma::Async::JobUtils

  DEPRECATED_DAYS_CUTOFF = 60

  sidekiq_options(Suma::Async.cron_job_options)
  cron "50 7 * * *"
  splay 2

  def _perform
    deleted = Suma::I18n::StaticString.where { deprecated_at < DEPRECATED_DAYS_CUTOFF.days.ago }.delete
    set_job_tags(deleted_rows: deleted)
  end
end
