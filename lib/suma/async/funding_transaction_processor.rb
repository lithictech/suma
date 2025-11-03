# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async/job_utils"

class Suma::Async::FundingTransactionProcessor
  extend Amigo::ScheduledJob
  include Suma::Async::JobUtils

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/5 * * * *"
  splay 30.seconds

  def _perform
    Suma::Payment::FundingTransaction.where(status: "created").each { |x| self.process(x, :collect_funds) }
    Suma::Payment::FundingTransaction.where(status: "collecting").each { |x| self.process(x, :collect_funds) }
  end

  def process(tx, m)
    member = tx.originating_payment_account.member
    tags = {member_id: member&.id, member_name: member&.name, funding_transaction_id: tx.id}
    self.with_log_tags(tags) { tx.process(m) }
  end
end
