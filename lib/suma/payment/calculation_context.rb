# frozen_string_literal: true

# CalculationContexts are used when we have to work against the balance
# of ledgers at the same time across time.
# For example, we may be debiting one ledger for a product;
# then processing another product,
# but don't want to re-debit that same ledger.
# CalculationContext takes care of this by allowing the caller
# to modify ledger balances in-memory.
#
# CalculationContexts should generally be created at the top level,
# like the API. This allows them to set up balance adjustments
# not already on the ledger.
# This also means that contexts must be immutable;
# if we mutated the context, it would make running the same calculation code
# non-idempotent.
class Suma::Payment::CalculationContext
  def initialize(apply_at, adjustments={})
    @apply_at = apply_at
    @adjustments = adjustments.freeze
  end

  # @return [Time]
  attr_reader :apply_at

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
  # @param contributions [Array<Suma::Payment::ChargeContribution,Hash,Suma::Payment::Trigger::PlanStep>]
  # @return [Suma::Payment::CalculationContext]
  def apply(*contributions)
    adj = @adjustments.dup
    contributions.each do |contrib|
      case contrib
        when Suma::Payment::ChargeContribution
          ledger = contrib.ledger
          amount = contrib.amount
        when Suma::Payment::Trigger::PlanStep
          ledger = contrib.receiving_ledger
          amount = -contrib.amount
        else
          ledger = contrib.fetch(:ledger)
          amount = contrib.fetch(:amount)
      end
      raise "cannot apply if no ledger" if ledger.nil?
      v = adj[ledger.id]
      v = v.nil? ? amount : (v + amount)
      adj[ledger.id] = v
    end
    return self.class.new(self.apply_at, adj)
  end
end
