# frozen_string_literal: true

# CalculationContexts are used when we have to work against the balance
# of ledgers at the same time across time. For example,
# we may be debiting one ledger for a product; then processing another product,
# but don't want to re-debit that same ledger.
# CalculationContext takes care of this by allowing the caller
# to modify ledger balances in-memory.
class Suma::Payment::CalculationContext
  def initialize
    @adjustments = {}
  end

  # Return the balance of the given ledger after adjustments (see +apply+).
  # @param [Suma::Payment::Ledger] ledger
  # @return [Money]
  def balance(ledger)
    balance = ledger.balance
    if (adj = @adjustments[ledger.id])
      balance -= adj
    end
    return balance
  end

  # Apply an adjustment so that when calculating the balance for the given +contrib.ledger+,
  # the given +contrib.amount+ is taken from the ledger's balance. For example, if +ledger+ has a balance of $0,
  # using `ctx.apply(ledger:, amount: Money.new(500))` and then `ctx.balance(ledger)` would return -$5.
  # @param contrib [Suma::Payment::ChargeContribution,Hash]
  def apply(contrib)
    case contrib
      when Suma::Payment::ChargeContribution
        ledger = contrib.ledger
        amount = contrib.amount
      else
        ledger = contrib.fetch(:ledger)
        amount = contrib.fetch(:amount)
    end
    raise "cannot apply if no ledger" if ledger.nil?
    v = @adjustments[ledger.id]
    v = v.nil? ? amount : (v + amount)
    @adjustments[ledger.id] = v
  end

  def apply_many(*contributions)
    contributions.each { |c| self.apply(c) }
  end
end
