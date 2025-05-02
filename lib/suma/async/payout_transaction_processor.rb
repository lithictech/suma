# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::PayoutTransactionProcessor
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/5 * * * *"
  splay 30.seconds

  def _perform
    Suma::Payment::PayoutTransaction.where(status: "created").each { |x| x.process(:send_funds) }
    Suma::Payment::PayoutTransaction.where(status: "sending").each { |x| x.process(:send_funds) }
  end
end
