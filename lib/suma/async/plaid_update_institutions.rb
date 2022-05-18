# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::PlaidUpdateInstitutions
  extend Amigo::ScheduledJob

  sidekiq_options retry: 10
  cron "13 10 * * *"
  splay 10.seconds

  def _perform
    unless Suma::Plaid.sync_institutions
      self.logger.warn("plaid_institutions not configured to sync")
      return
    end
    Suma::PlaidInstitution.update_all
  end
end
