# frozen_string_literal: true

require "amigo/scheduled_job"

require "suma/payment/platform_status"

# Each morning, try charging ledgers with non-zero balances.
class Suma::Async::LedgerBalanceCharger
  extend Amigo::ScheduledJob

  include Suma::Async::JobUtils

  sidekiq_options(Suma::Async.cron_job_options)
  cron "12 */3 * * *"
  splay 60.seconds

  def _perform
    unbalanced = Suma::Payment::PlatformStatus.new.unbalanced_ledgers_dataset.all
    unbalanced.select! { |led| led.balance.negative? }
    unbalanced.select! { |led| led === led.account.cash_ledger }
    unbalanced.each do |led|
      instrument = led.account.member.default_payment_instrument
      next unless instrument
      begin
        Suma::Payment::FundingTransaction.start_new(
          led.account,
          amount: -led.balance,
          instrument:,
          memo: Suma::I18n::StaticString.find_text("backend", "funding_transaction_charge_balance"),
          collect: :must,
        )
      rescue StateMachines::Sequel::FailedTransition
        nil
      end
    end
  end
end
