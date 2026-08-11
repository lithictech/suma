# frozen_string_literal: true

# Adds some price helpers.
# Requires :quantity and :offering_product
module Suma::Commerce::PricedItem
  def undiscounted_cost = self.quantity * self.offering_product.undiscounted_price
  def customer_cost = self.quantity * self.offering_product.customer_price
  def savings = self.undiscounted_cost - self.customer_cost

  def self.ideal_ledger_charge_contributions(context, payment_account, priced_items)
    return self.ledger_charge_contributions(context, payment_account:, priced_items:, mode: :ideal)
  end

  def self.actual_ledger_charge_contributions(context, payment_account, priced_items)
    return self.ledger_charge_contributions(context, payment_account:, priced_items:, mode: :actual)
  end

  # Return contributions from each ledger that can be used for paying for the order.
  # NOTE: Right now this is only product contributions; when we support tax and handling,
  # we'll need to modify this routine to factor those into the right (cash?) ledger.
  #
  # @param payment_account [Suma::Payment::Account]
  # @param priced_items [Array<Suma::Commerce::PricedItem>]
  # @param context [Suma::Payment::CalculationContext]
  # @return [Suma::Payment::ChargeContribution::Collection]
  def self.ledger_charge_contributions(context, payment_account:, priced_items:, mode:)
    calc_ctx = context
    collections = priced_items.map do |item|
      args = [calc_ctx, payment_account, item.offering_product.product, item.customer_cost]
      coll = case mode
        when :ideal
          Suma::Payment::ChargeContribution.find_ideal_cash_contribution(*args)
        when :actual
          Suma::Payment::ChargeContribution.find_actual_contributions(*args)
        else
          raise ArgumentError, "invalid mode: #{mode}"
      end
      calc_ctx = calc_ctx.apply_debits(*coll.all)
      calc_ctx = calc_ctx.record_trigger_step_contributions(coll.relevant_trigger_steps)
      # This is tricky. When we are processing multiple items,
      # and there are trigger subsidies, we will add the subsidy to a ledger.
      # But then the next items will see this positive balance and try to use it.
      # Instead, we need to debit *only the added subsidy* for future subsidy calculations.
      # We want to make sure:
      # 1) existing subsidy (not due to a trigger) is used,
      # 2) added subsidy due to a trigger is not used for future steps,
      # 3) figuring out the subsidy keeps track of what was subsidized
      #   (see #record_trigger_step_contributions).
      subsidy_readjustments = coll.relevant_trigger_steps.map do |step|
        {ledger: step.receiving_ledger, amount: step.amount, trigger: step.trigger}
      end
      calc_ctx = calc_ctx.apply_credits(*subsidy_readjustments)
      coll
    end
    consolidated_contributions = Suma::Payment::ChargeContribution::Collection.consolidate(context, collections)
    return consolidated_contributions
  end
end
