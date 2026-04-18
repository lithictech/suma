# frozen_string_literal: true

require "suma/payment/ledger"
require "suma/payment/platform_status"

class Suma::Payment::Ledger::BalanceCharger
  def run
    self.find_ledgers.each do |ledger|
      self.charge_ledger(ledger)
    end
  end

  # Find all the unbalanced ledgers in the system
  def find_ledgers
    unbalanced = Suma::Payment::PlatformStatus.new.unbalanced_ledgers_dataset.all
    unbalanced.select! { |led| led.balance.negative? }
    unbalanced.select! { |led| led === led.account.cash_ledger }
    return unbalanced
  end

  # Find the instruments to charge the owner of the ledger,
  # in their preferred order.
  def instruments_to_charge(ledger)
    default = ledger.account.member.default_payment_instrument
    return [] if default.nil?
    others = ledger.account.member.public_payment_instruments.
      select { |pi| pi.status == :ok }.
      reject { |pi| pi === default }
    return [default] + others
  end

  # Charge the ledger its balance, using the instruments to charge.
  # Return the first successful funding transaction, or nil if none worked.
  def charge_ledger(ledger)
    instruments = instruments_to_charge(ledger)
    instruments.each do |instrument|
      fx = self.charge_instrument(ledger, instrument)
      return fx if fx
    end
    return nil
  end

  # Return the funding transaction, or nil if it failed.
  def charge_instrument(ledger, instrument)
    ledger.db.transaction do
      ledger.account.lock!
      ledger.refresh
      return nil unless ledger.balance.negative?
      begin
        fx = Suma::Payment::FundingTransaction.start_new(
          ledger.account,
          amount: -ledger.balance,
          instrument:,
          memo: self.memo,
          collect: :must,
        )
        return fx
      rescue StateMachines::Sequel::FailedTransition, Suma::Payment::FundingTransaction::CollectFundsFailed
        # We don't care about failures here; we'll try again later.
        # We can report long-term negative balances separately.
        return nil
      end
    end
  end

  def memo = @memo ||= Suma::I18n::StaticString.find_text("backend", "funding_transaction_charge_balance")
end
