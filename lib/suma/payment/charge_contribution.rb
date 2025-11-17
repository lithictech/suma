# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::ChargeContribution < Suma::TypedStruct
  class InvalidCalculation < StandardError; end

  attr_reader :ledger, :apply_at, :amount, :category

  def _defaults
    return {amount: Money.new(0)}
  end

  # @!attribute ledger
  # Ledger for the contribution. Is nil for the 'remainder' ledger.
  # @return [Suma::Payment::Ledger]

  # @!attribute apply_at
  # @return [Time]

  # @!attribute amount
  # @return [Money]

  # @!attribute category
  # @return [Suma::Vendor::ServiceCategory]

  # Return the amount minus the current ledger balance.
  # In most cases, this is not super relevant,
  # since the charge contribution isn't dealing with funding (just charging).
  # But this will help us know if our charge will send a ledger negative, for example,
  # especially a cash ledger which only has a balance modified after a 3rd-party side effect
  # like a credit card charge.
  # @return [Money]
  def outstanding = [self.amount - self._nonnegative_balance, Money.new(0, self.amount.currency)].max
  def outstanding? = !self.outstanding.zero?

  # Return the amount of this contribution that is coming from the balance,
  # rather than an additional funding.
  # See +outstanding+ for more context. Useful to differentiate what is a new vs. transfer
  # on a cash ledger.
  # @return [Money]
  def from_balance = [self._nonnegative_balance, self.amount].min
  def from_balance? = !self.from_balance.zero?

  # Return 0 or the current ledger balance, whichever is higher.
  # We do not take into account negative balances when determining charge contributions;
  # this would introduce too much complexity and ambiguity, especially when things like figuring out
  # the contributions for multiple products within an order; which of them is responsible for paying off
  # the negative balance? It would be very confusing. Instead, if we need to worry about
  # negative balances, we can add them as separate line items;
  # for example, if you have a -$5 balance on your cash ledger,
  # we could calculate the cost of your cart with an additional $5 'cash product' ("existing ledger balance")
  # you'd have to pay for.
  private def _nonnegative_balance = [Money.new(0, self.amount.currency), self.ledger.balance].max

  def amount? = !self.amount.zero?

  # Replace +amount+ on the receiver.
  # Generally you'll want to use +dup+ to keep things immutable,
  # but in certain cases you may need to modify the +amount+ directly.
  # @return [ChargeContribution]
  def mutate_amount(v)
    @amount = v
    return self
  end

  # @return [ChargeContribution]
  def mutate_category(v)
    @category = v
    return self
  end

  # @return [ChargeContribution]
  def dup(**kw)
    p = {
      ledger: self.ledger,
      apply_at: self.apply_at,
      amount: self.amount,
      category: self.category,
    }
    p.merge!(kw)
    return self.class.new(**p)
  end

  # Collection of related charge contributions from various ledgers.
  class Collection < Suma::TypedStruct
    # @return [Suma::Payment::CalculationContext]
    attr_reader :context

    # The contribution from the cash ledger, using its existing balance.
    # Its amount will be 0 if other ledgers cover the full amount,
    # or its balance is 0.
    # Its category is always nil.
    # @return [Suma::Payment::ChargeContribution]
    attr_reader :cash

    # The contributions from other ledgers.
    # @return [Array<Suma::Payment::ChargeContribution>]
    attr_reader :rest

    # If, when calculating the collection, some total could not be reached,
    # +remainder+ should be set to indicate the unreached portion.
    # @return [Money]
    attr_accessor :remainder

    # If, when calculating the collection, payment trigger contributions were used,
    # these were the steps relating to the contributions.
    # @return [Array<Suma::Payment::Trigger::Step>]
    attr_accessor :relevant_trigger_steps

    # @param [Suma::Payment::Trigger::Plan] funding_plan
    # @return [self]
    def set_relevant_trigger_steps_from(funding_plan)
      candidate_ledger_ids = self.all.to_set { |c| c.ledger.id }
      self.relevant_trigger_steps = funding_plan.steps.select do |st|
        candidate_ledger_ids.include?(st.receiving_ledger.id)
      end
      return self
    end

    def remainder? = !self.remainder.zero?

    def _defaults
      return {remainder: Money.new(0), rest: [], relevant_trigger_steps: []}
    end

    # @param cash [:first,:last] Where to include the cash contribution in the list of all.
    # @return [Enumerable<Suma::Payment::ChargeContribution>]
    def all(cash: :first, &block)
      return to_enum(:all, cash:) unless block
      yield self.cash if cash == :first
      self.rest.each(&block)
      yield self.cash if cash == :last
    end

    # @return [Suma::Payment::ChargeContribution::Collection]
    def self.create_empty(context, cash_ledger)
      return Suma::Payment::ChargeContribution::Collection.new(
        context:,
        cash: Suma::Payment::ChargeContribution.new(
          ledger: cash_ledger,
          apply_at: context.apply_at,
          amount: Money.new(0),
          category: Suma::Vendor::ServiceCategory.cash,
        ),
      )
    end

    # Merge many contribution collections together.
    # +cash+ amounts are summed, while the +rest+ array
    # has a unique entry for each ledger.
    # Note that +rest+ contributions will the +category+ of one contribution;
    # consolidation is inherently lossy, so if one +rest+ ledger supports multiple categories
    # (say "food" ledger for "organic" and "local" categories) it will have only one of those categories.
    # @param [Suma::Payment::CalculationContext] ctx
    # @param [Array<Collection>] collections
    # @return [Collection]
    def self.consolidate(ctx, collections)
      raise ArgumentError, "collections cannot be empty" if collections.empty?
      result = self.new(
        context: ctx,
        cash: collections[0].cash.dup,
        rest: collections[0].rest.map(&:dup),
        remainder: collections[0].remainder,
        relevant_trigger_steps: collections[0].relevant_trigger_steps.dup,
      )
      collections[1..].each do |col|
        result.cash.mutate_amount(result.cash.amount + col.cash.amount)
        result.remainder += col.remainder
        result.relevant_trigger_steps.concat(col.relevant_trigger_steps)
        col.rest.each do |c|
          other_contrib = result.rest.find do |r|
            r.ledger === c.ledger && r.category === c.category
          end
          if other_contrib.nil?
            result.rest << c.dup
          else
            other_contrib.mutate_amount(other_contrib.amount + c.amount)
          end
        end
      end
      return result
    end
  end

  # Runs a simulation to find the ideal cash contribution to take advantage of all payment triggers.
  #
  # See docs/payment-automation.md for additional details.
  #
  # This code runs +Suma::Payment::Account#calculate_charge_contributions+
  # with a number of different contexts, to find the minimum cash charge
  # (funding transaction) that would result in enough triggered payments/subsidies
  # to cover the given amount.
  #
  # The order this takes is:
  #
  # - Use $0 cash. It's possible we can cover the full amount using existing ledger subsidy.
  # - Use $amount cash. If we have any cash balance left on our ledger,
  #   we start bisecting.
  # - Run an iterative bisect. Start with $candidate=$amount/2.
  #   Add cash of $candidate amount and:
  #   - If we have a balance on our cash ledger, it's possible we can contribute less.
  #     Set $candidate=$candidate/2**stepnum (bisect between the current candidate and $0).
  #   - If we have no remainder and no balance on our cash ledger,
  #     we've hit the correct amount exactly.
  #   - If we have a remainder (which implies we have no cash ledger balance),
  #     we need to contribute more cash. Set $candidate=$candidate+$candidate/2**stepnum
  #     (bisect between the current and previous candidate).
  # - Keep going until we hit the correct amount (as above).
  # - If we don't hit the correct amount, raise an error.
  #   In theory it would be ok to find a 'minimum' charge that leaves a remainder,
  #   but given the limitations above (that we need to maintain $0 on the cash ledger),
  #   we need to error if we don't find an exact match.
  #   Note: This case may be impossible. We do not have a unit test for it.
  # - If the correct amount is less than the minimum funding amount, raise an error.
  #
  # @param context [Suma::Payment::CalculationContext]
  # @param account [Suma::Payment::Account]
  # @param has_vnd_svc_categories [Suma::Vendor::HasServiceCategories]
  # @param amount [Money]
  # @return [Suma::Payment::ChargeContribution::Collection]
  def self.find_ideal_cash_contribution(context, account, has_vnd_svc_categories, amount)
    cash = account.cash_ledger!

    # If there's no remainder, we are able to cover the cost from existing ledgers (or because it's a $0 amount).
    # Don't need to charge the user anything new.
    charges_using_existing_ledgers = self.find_actual_contributions(context, account, has_vnd_svc_categories, amount)
    return charges_using_existing_ledgers unless charges_using_existing_ledgers.remainder?

    # We do not worry about existing negative balances on the ledger.
    # See _nonnegative_balance above.
    # This is especially important here, because we may call find_ideal_cash_contribution
    # for each product in a cart; the contributions for the first product create a negative ledger balance.
    # This second product would need to be charged for the deficit left by the first product, etc.
    # Instead, reason about negative balances, as additional charges;
    # it's simpler and more flexible, too (for example it will make it easier to do something like
    # bring the negative balance up to a minimum, rather than $0).
    #
    # Get the original balance, and if it's negative, treat it as a 'credit' so we don't calculate it.
    original_cash_balance = [context.balance(cash), Money.new(0, amount.currency)].min

    # We'll need to run triggers to calculate subsidy.
    triggers = context.cached_get("triggers-#{account.id}") do
      Suma::Payment::Trigger.gather(account, active_as_of: context.apply_at)
    end
    # Bisect until we find a funding amount that results in no remainder,
    # and no leftover cash.
    candidate = amount
    loop_number = 1
    loop do
      subsidy_plan = triggers.funding_plan(context, amount: candidate, up_to: amount)
      candidate_charges = self.find_actual_contributions(
        context.apply_credits(
          {ledger: cash, amount: candidate + -original_cash_balance},
          *subsidy_plan.steps.map { |st| {ledger: st.receiving_ledger, amount: st.amount, trigger: st.trigger} },
        ),
        account,
        has_vnd_svc_categories,
        amount,
      )
      candidate_charges.set_relevant_trigger_steps_from(subsidy_plan)
      # Figure out how much 'additional' cash is needed, by taking the amount we need to cover the bill,
      # and subtracting what we'd contribute without any additional funds (this is normally the balance).
      # If the additional funds we need to charge, is equal to the candidate, then this is ideal, because:
      # - If the additional funds to charge is less than the candidate, we added too much cash,
      #   and we have extra balance on our cash ledger, which we don't want.
      # - If we need more funds (there is a remainder), the candidate was not high enough.
      additional_cash = candidate_charges.cash.amount - charges_using_existing_ledgers.cash.amount
      return candidate_charges if !candidate_charges.remainder? && candidate == additional_cash
      step = amount / (2**loop_number)
      if step.zero?
        # It may be that there is no whole cent cash contribution that will yield amount exactly.
        #   original_ledger_balance + cash_contribution + (cash_contribution * trigger_multiplier) = cart_total
        # For example, there is no cent value of x for:
        #   $3 + $x + ($x * 3.8) = $24
        # To solve this, we'd need to either support fractional cents,
        # or allow a positive cash balance to be left on the ledger
        # (choose the lowest contribution that yields a result >= amount).
        # Rather than allowing a positive cash balance, we error, but this can change in the future.
        msg = <<~MSG
          Got a $0 step bisecting #{amount} #{loop_number} times. Usually this happens because
          there is no whole cent value that can be processed by payment triggers,
          and added to the current cash balance, to yield the target amount.
          The cash ledger balance should be zero'ed out,
          or non-cash ledgers can get a balance added such that the subsidy can be added cleanly.
          Cash ledger: #{cash.inspect}
          Balance: #{context.balance(cash)}
          Target amount: #{amount}
          Loops: #{loop_number}
          Subsidy plan: #{subsidy_plan.inspect}
        MSG
        raise InvalidCalculation, msg
      end
      needs_more_cash = candidate_charges.remainder?
      # NOTE: It is possible the candidate is below the minimum funding amount,
      # but that is handled elsewhere.
      step *= -1 unless needs_more_cash
      candidate += step
      loop_number += 1
      # This should rarely be hit- we'd get a $0 step first for all but very large amounts.
      raise "failed to bisect #{amount} after #{loop_number} attempts" if loop_number >= 100
    end
  end

  # Helper to maintain signature parity with +find_ideal_cash_contribution+.
  def self.find_actual_contributions(context, account, has_vnd_svc_categories, amount)
    return account.calculate_charge_contributions(context, has_vnd_svc_categories, amount)
  end
end
