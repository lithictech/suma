# frozen_string_literal: true

require "suma/automation_trigger"

class Suma::AutomationTrigger::FundingTransactionMatch < Suma::AutomationTrigger::Action
  def run
    funding_xaction = Suma::Payment::FundingTransaction.find!(self.event.payload.first)
    # Only match this transaction if it was a 'normal' fund add, not commerce.
    # It doesn't make sense to match commerce funding movements since they have already used it to pay.
    return unless funding_xaction.associated_charges_dataset.empty?
    acct = funding_xaction.originating_payment_account
    member = acct.member
    params = self.params
    return unless self.member_passes_constraints?(member.id, params[:verified_constraint_name])
    self.automation_trigger.db.transaction do
      vsc = Suma::Vendor::ServiceCategory.find!(name: params.fetch(:category_name))
      ledger = acct.ledgers_dataset[name: params.fetch(:ledger_name)]
      contribution_text = Suma::TranslatedText.create(**params.fetch(:contribution_text))
      memo = if params[:subsidy_memo].nil?
               contribution_text
             else
               Suma::TranslatedText.create(**params.fetch(:subsidy_memo))
      end
      if ledger.nil?
        ledger = acct.add_ledger(
          currency: Suma.default_currency,
          name: params.fetch(:ledger_name),
          contribution_text:,
        )
        ledger.add_vendor_service_category(vsc)
      end
      ledger.lock!
      ratio = params.fetch(:match_ratio, 1)
      amount = funding_xaction.amount * ratio
      if (max_cents = params.fetch(:max_cents, nil))
        max_amount = Money.new(max_cents, amount.currency)
        amount = [amount, max_amount].min
        balance = ledger.balance
        # Treat the max amount as both the maximum individual contribution,
        # AND the maximum total subsidy.
        amount = max_amount - balance if amount + balance > max_amount
      end
      return if amount.zero?
      Suma::Payment::BookTransaction.create(
        apply_at: Time.now,
        amount:,
        originating_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(vsc),
        receiving_ledger: ledger,
        associated_vendor_service_category: vsc,
        memo:,
      )
    end
  end
end
