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
    collections = priced_items.map do |item|
      args = [context, payment_account, item.offering_product.product, item.customer_cost]
      coll = case mode
        when :ideal
          Suma::Payment::ChargeContribution.find_ideal_cash_contribution(*args)
        when :actual
          Suma::Payment::ChargeContribution.find_actual_contributions(*args)
        else
          raise ArgumentError, "invalid mode: #{mode}"
      end
      context = context.apply_debits(*coll.all)
      coll
    end
    consolidated_contributions = Suma::Payment::ChargeContribution::Collection.consolidate(context, collections)
    return consolidated_contributions
  end
end
