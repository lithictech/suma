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
  def initialize(apply_at, adjustments: {}, adjustments_computed: {})
    @apply_at = apply_at
    @adjustments = adjustments.freeze
    @adjustments_computed = adjustments_computed.freeze
  end

  # @return [Time]
  attr_reader :apply_at

  # Return the balance of the given ledger after adjustments (see +apply+).
  # @param [Suma::Payment::Ledger] ledger
  # @return [Money]
  def balance(ledger)
    balance = ledger.balance
    if (adj = @adjustments_computed[ledger.id])
      balance += adj
    end
    return balance
  end

  def adjustments_for(ledger)
    return @adjustments.fetch(ledger.id, [])
  end

  # Apply an adjustment so that when calculating the balance for the given +contrib.ledger+,
  # the given +contrib.amount+ is taken from the ledger's balance. For example, if +ledger+ has a balance of $0,
  # using `ctx.apply_debits(ledger:, amount: Money.new(500))` and then `ctx.balance(ledger)` would return -$5.
  #
  # @param contributions [Array<Suma::Payment::ChargeContribution,Hash>] Valid keys are :ledger, :amount, and :trigger.
  #   :trigger is used when this adjustment is due to a +Suma::Payment::Trigger+ running.
  # @return [Suma::Payment::CalculationContext]
  def apply_debits(*contributions) = self.apply(contributions, :debit)

  # Same as +apply_debits+, but each amount will be added to the ledger balance.
  #
  # @param contributions [Array<Suma::Payment::ChargeContribution,Hash>]
  # @return [Suma::Payment::CalculationContext]
  def apply_credits(*contributions) = self.apply(contributions, :credit)

  protected def apply(contributions, type)
    adjustments = @adjustments.dup
    adjustments_computed = @adjustments_computed.dup
    contributions.each do |contrib|
      adj = case contrib
        when Suma::Payment::ChargeContribution
          Adjustment.new(ledger: contrib.ledger, amount: contrib.amount, type:)
        else
          Adjustment.new(**contrib, type:)
      end
      raise "cannot apply if no ledger" if adj.ledger.nil?
      ledger_id = adj.ledger.id
      existing_adjustment = adjustments_computed.fetch(ledger_id, 0)
      adjustments_computed[ledger_id] = existing_adjustment + adj.balance_amount
      these_adj = adjustments[ledger_id] ||= []
      these_adj << adj
    end
    return self.class.new(self.apply_at, adjustments:, adjustments_computed:)
  end

  class Adjustment < Suma::TypedStruct
    attr_accessor :ledger, :amount, :trigger, :type

    def balance_amount = self.type == :credit ? self.amount : (self.amount * -1)
  end
end
