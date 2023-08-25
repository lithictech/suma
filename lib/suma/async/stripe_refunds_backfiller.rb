# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async"
require "suma/webhookdb"

class Suma::Async::StripeRefundsBackfiller
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/30 * * * *"
  splay 60

  def _perform
    Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy.backfill_payouts_from_webhookdb
  end
end
