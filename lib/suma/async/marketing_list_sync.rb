# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async"

class Suma::Async::MarketingListSync
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "50 6 * * *"
  splay 5

  def _perform
    specs = Suma::Marketing::List::Specification.gather_all
    Suma::Marketing::List.rebuild_all(*specs)
  end
end
