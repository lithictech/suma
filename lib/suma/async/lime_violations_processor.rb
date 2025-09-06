# frozen_string_literal: true

require "amigo/scheduled_job"
require "amigo/advisory_locked"
require "suma/async"
require "suma/lime/handle_violations"

class Suma::Async::LimeViolationsProcessor
  extend Amigo::ScheduledJob

  sidekiq_options(
    Suma::Async.cron_job_options.merge(advisory_lock: {db: Suma::Member.db}),
  )
  cron "41 * * * * *"
  splay 30.seconds

  def _perform
    return unless Suma::Lime.violations_processor_enabled
    Suma::Lime::HandleViolations.new.run
  end
end
