# frozen_string_literal: true

require "suma/payment/ledger"
require "suma/payment/platform_status"

class Suma::Payment::Ledger::BalanceCharger
  # Result of the balance charge.
  # At most one of the fields are set:
  # - funding_transaction: Something was charged.
  # - no_balance: There was no balance to charge.
  # - error: Charge failed.
  # If nothing is set, it means multiple charges were attempted
  # (ie, each instrument), and all of them errored.
  class Result < Suma::TypedStruct
    attr_reader :funding_transaction, :no_balance, :error

    def _defaults = {funding_transaction: nil, no_balance: false, error: nil}

    def ok? = self.funding_transaction || self.no_balance
  end

  NO_BALANCE_RESULT = Result.new(no_balance: true)

  class << self
    # If the given account has a cash ledger with a negative balance,
    # change its balance to the given instrument.
    # Return the funding transaction or nil if unchanged.
    # @param account [Suma::Payment::Acount]
    # @param instrument [Suma::Payment::Instrument]
    # @return [Result]
    def charge_balance_to(account, instrument)
      return NO_BALANCE_RESULT if account.nil?
      bc = self.new
      ledger = bc.unbalanced_ledgers_dataset.where(account_id: account.id).first
      return NO_BALANCE_RESULT if ledger.nil?
      r = bc.charge_instrument(ledger, instrument, reraise: true)
      return r
    end
  end

  # @return [Array<Result>]
  def run
    ds = self.unbalanced_ledgers_dataset.all
    result = ds.map { |ledger| self.charge_ledger(ledger) }
    return result
  end

  # Find all the unbalanced ledgers in the system
  def unbalanced_ledgers_dataset
    balance_view = Suma::Payment::Ledger::Balance.
      dataset.
      where { balance_cents < Suma::Payment.minimum_cash_balance_grace_cents }
    unbalanced = Suma::Payment::PlatformStatus.new.
      unbalanced_ledgers_dataset.
      cash.
      where(balance_view:)
    return unbalanced
  end

  # Find the instruments to charge the owner of the ledger,
  # in their preferred order.
  # @return [Array<Suma::Payment::Instrument::Interface>]
  def instruments_to_charge(ledger)
    default = ledger.account.member.default_payment_instrument
    return [] if default.nil?
    others = ledger.account.member.public_payment_instruments.reject { |pi| pi === default }
    instruments = [default] + others
    instruments.select!(&:usable_for_funding?)
    return instruments
  end

  # Charge the ledger its balance, using the instruments to charge.
  # Return the first successful funding transaction, or nil if none worked.
  # @return [Result]
  def charge_ledger(ledger)
    instruments = instruments_to_charge(ledger)
    instruments.each do |instrument|
      r = self.charge_instrument(ledger, instrument)
      return r if r.ok?
    end
    return Result.new
  end

  # Return the funding transaction, or nil if it failed.
  # @param instrument [Suma::Payment::Instrument::Interface]
  # @return [Result]
  def charge_instrument(ledger, instrument, reraise: false)
    raise Suma::InvalidPrecondition, "#{instrument.admin_label} cannot be used for funding" unless
      instrument.usable_for_funding?
    ledger.db.transaction do
      ledger.account.lock!
      ledger.refresh
      return NO_BALANCE_RESULT unless Suma::Payment.chargeable_balance?(ledger.balance)
      fx = Suma::Payment::FundingTransaction.start_new(
        ledger.account,
        amount: -ledger.balance,
        instrument:,
        memo: self.memo,
        collect: :must,
      )
      return Result.new(funding_transaction: fx)
    end
  rescue StateMachines::Sequel::FailedTransition, Suma::Payment::FundingTransaction::CollectFundsFailed => e
    raise e if reraise
    # Must be OUTSIDE the db transaction.
    # We don't care about failures here; we'll try again later.
    # We can report long-term negative balances separately.
    return Result.new(error: e)
  end

  def memo = @memo ||= Suma::I18n::StaticString.find_text("backend", "funding_transaction_charge_balance")
end
