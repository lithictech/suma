# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::PlaidUpdateInstitutions
  extend Amigo::ScheduledJob
  include Suma::Async::JobUtils

  sidekiq_options(Suma::Async.cron_job_options.merge(retry: 10))
  cron "13 10 * * *"
  splay 10.seconds

  def _perform
    unless Suma::Plaid.sync_institutions
      self.set_job_tags(result: "plaid_institutions not configured to sync")
      return
    end
    Suma::PlaidInstitution.update_all
  end
end
