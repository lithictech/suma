# frozen_string_literal: true

# Abstract base class that charges a member for some good or service.
#
# This code encapsulates the logic around:
# - Creating a charge,
# - Calculating the creating the ideal book transactions (subsidy, cash),
# - Calculating and creating the book transactions that originate subsidies
#   from the proper ledgers,
# - Creating the book transaction that originates any additional cash necessary,
# - Creating the funding transaction to cover any remainder.
class Suma::Charge::Charger
  attr_reader :member, :apply_at

  def initialize(
    member:,
    apply_at:,
    undiscounted_subtotal:,
    charge_kwargs:
  )
    @member = member
    @apply_at = apply_at
    @undiscounted_subtotal = undiscounted_subtotal
    @charge_kwargs = charge_kwargs
  end

  def charge
    @member.db.transaction do
      charge = Suma::Charge.create(
        member: @member,
        undiscounted_subtotal: @undiscounted_subtotal,
        **@charge_kwargs,
      )

      # We need to re-calculate how much to charge the member
      # so we can add triggered subsidy payments onto the ledger before charging.
      predicted_contrib = self.predicted_charge_contributions
      self.verify_predicted_contribution(predicted_contrib)
      # This will make member subledgers have a positive balance.
      # It will not debit the subledgers or cash ledger.
      Suma::Payment::Trigger::Plan.new(steps: predicted_contrib.relevant_trigger_steps).
        execute(ledgers: predicted_contrib.all.map(&:ledger), at: apply_at)

      self.member.refresh
      # See how much the member needs to pay across cash and noncash ledgers,
      # and what is not covered by existing balances.
      actual_contrib = self.actual_charge_contributions
      if actual_contrib.remainder?
        actual_contrib.cash.mutate_amount(actual_contrib.cash.amount + actual_contrib.remainder)
      end
      debitable = actual_contrib.all.select(&:amount?)
      # Create ledger debits for all positive contributions.
      # This will probably make our cash ledger balance negative;
      # the funding transaction will bring it back to zero.
      book_xactions = @member.payment_account.debit_contributions(
        debitable,
        memo: self.contribution_memo,
      )
      # Instead of an itemized charge receipt, just add each transaction as an item.
      # We will use the order itself to create an itemized receipt.
      book_xactions.each do |x|
        charge.add_contributing_book_transaction(x)
      end

      # If there are any remainder contributions, we need to fund them against the cash ledger.
      if actual_contrib.remainder? && (funding = self.start_funding_transaction(amount: actual_contrib.remainder))
        charge.add_associated_funding_transaction(funding)
      end
      return charge
    end
  end

  # Return the charge contributions that will pay for this charge.
  # Should call +Suma::Payment::ChargeContribution.find_ideal_cash_contribution+.
  # @return [Suma::Payment::ChargeContribution::Collection]
  def predicted_charge_contributions = raise NotImplementedError

  # Verify that the predicted contribution equals what we expect to pay.
  # Usually this is used when the user is shown an amount,
  # and then charged, and we want to verify what was shown,
  # is what they will be charged.
  # @return [Suma::Payment::ChargeContribution::Collection]
  def verify_predicted_contribution(_contrib) = raise NotImplementedError

  # Return the actual charge contributions that will pay for this charge,
  # based on what is on the ledger.
  # Should call +Suma::Payment::ChargeContribution.find_actual_contributions+.
  # @return [Suma::Payment::ChargeContribution::Collection]
  def actual_charge_contributions = raise NotImplementedError

  # All book transactions used to pay will have this memo.
  # @return [Suma::TranslatedText]
  def contribution_memo = raise NotImplementedError

  # Create a funding transaction of the given amount.
  # Amount is always positive.
  # Return nil if none is created.
  # @return [Suma::Payment::FundingTransaction,nil]
  def start_funding_transaction(amount:) = raise NotImplementedError
end
