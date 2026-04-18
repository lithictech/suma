# frozen_string_literal: true

require "amigo/scheduled_job"

require "suma/payment/ledger/balance_charger"

# Each morning, try charging ledgers with non-zero balances.
class Suma::Async::LedgerBalanceCharger
  extend Amigo::ScheduledJob

  include Suma::Async::JobUtils

  sidekiq_options(Suma::Async.cron_job_options)
  cron "12 */#{Suma::Payment.charge_negative_balances_hour_interval} * * *"
  splay 60.seconds

  def _perform
    return if Suma::Payment.charge_negative_balances_disabled
    Suma::Payment::Ledger::BalanceCharger.new.run
  end
end
