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
  EMPTY_HASH = {}.freeze

  def initialize(apply_at)
    @apply_at = apply_at
    @adjustments = EMPTY_HASH
    @adjustments_computed = EMPTY_HASH
    @trigger_contributions = EMPTY_HASH
    @cache = {}
  end

  # @return [Time]
  attr_reader :apply_at

  # Return an instance using the new fields.
  # Mutable fields (like the cache) as shared.
  def duplicate_with(adjustments: nil, adjustments_computed: nil, trigger_contributions: nil)
    d = self.class.new(self.apply_at)
    adjustments ||= @adjustments
    adjustments_computed ||= @adjustments_computed
    trigger_contributions ||= @trigger_contributions
    d.instance_variable_set(:@adjustments, adjustments.freeze)
    d.instance_variable_set(:@adjustments_computed, adjustments_computed.freeze)
    d.instance_variable_set(:@trigger_contributions, trigger_contributions.freeze)
    d.instance_variable_set(:@cache, @cache)
    return d
  end

  # Return each of the adjusted ledgers.
  # @return [Array<Suma::Payment::Ledger]
  def ledgers = @adjustments.values.map { |adjs| adjs.first.ledger }

  # Invoke the yielded block to get the value stored at key,
  # and then return that value for the lifetime of the context,
  # and all spawned contexts.
  #
  # Can be used to avoid re-querying the database when the same database-querying method
  # needs to be called many times.
  #
  # IMPORTANT: This must only be used for queries that do not change over the context
  # (or child context) lifetimes, since the cache is shared.
  # That is, it should not be used for things like balances, or in calculations that vary
  # during the calculation (like payment trigger contributions via executions).
  def nonvarying_cached_get(key, &)
    return @cache[key] if @cache.include?(key)
    v = yield
    @cache[key] = v
    return v
  end

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

  def adjustments_for(ledger) = @adjustments.fetch(ledger.id, [])

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
    return self.duplicate_with(adjustments:, adjustments_computed:)
  end

  def contributions_from_trigger(trigger, ledger)
    contrib = @trigger_contributions[trigger.id]
    return Money.zero if contrib.nil?
    return contrib.fetch(ledger.id, Money.zero)
  end

  # Record trigger executions in-memory so they can be used later when figuring out trigger plans.
  # @param [Array<Suma::Payment::Trigger::PlanStep>] steps
  def record_trigger_step_contributions(steps)
    d = @trigger_contributions.dup
    steps.each do |step|
      d[step.trigger.id] ||= {}
      d[step.trigger.id][step.ledger.id] ||= Money.zero
      d[step.trigger.id][step.ledger.id] += step.amount
    end
    return self.duplicate_with(trigger_contributions: d)
  end

  def inspect
    return "#<%p %s>" % [self.class, @adjustments]
  end

  alias to_s inspect if ENV["DEBUGGER_HOST"]

  class Adjustment < Suma::TypedStruct
    attr_accessor :ledger, :amount, :trigger, :type

    def balance_amount = self.type == :credit ? self.amount : (self.amount * -1)
  end
end
