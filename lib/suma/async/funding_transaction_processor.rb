# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::FundingTransactionProcessor
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/5 * * * *"
  splay 30.seconds

  def _perform
    Suma::Payment::FundingTransaction.where(status: "created").each { |x| x.process(:collect_funds) }
    Suma::Payment::FundingTransaction.where(status: "collecting").each { |x| x.process(:collect_funds) }
  end
end
