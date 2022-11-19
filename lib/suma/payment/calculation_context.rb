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

  def balance(ledger)
    balance = ledger.balance
    if (adj = @adjustments[ledger.id])
      balance -= adj
    end
    return balance
  end

  # @param contrib [Suma::Payment::ChargeContribution]
  def apply(contrib)
    return if contrib.remainder?
    v = @adjustments[contrib.ledger.id]
    v = v.nil? ? contrib.amount : (v + contrib.amount)
    @adjustments[contrib.ledger.id] = v
  end

  def apply_all(contributions)
    contributions.each { |c| self.apply(c) }
  end
end
