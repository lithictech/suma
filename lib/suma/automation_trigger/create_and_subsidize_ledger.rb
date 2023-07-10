# frozen_string_literal: true

require "suma/automation_trigger"

class Suma::AutomationTrigger::CreateAndSubsidizeLedger < Suma::AutomationTrigger::Action
  def run
    member = Suma::Member.find!(self.event.payload.first)
    acct = Suma::Payment::Account.find_or_create_or_find(member:)
    params = self.automation_trigger.parameter.deep_symbolize_keys
    if (constraint_name = params[:verified_constraint_name])
      constraints_ds = Suma::Eligibility::Constraint.where(name: constraint_name)
      member_passes_constraints = !Suma::Member.
        where(id: member.id).
        where(verified_eligibility_constraints: constraints_ds).
        empty?
      return unless member_passes_constraints

    end
    self.automation_trigger.db.transaction do
      acct.lock!
      ledger_exists = !acct.ledgers_dataset.where(name: params[:ledger_name]).empty?
      return if ledger_exists
      ledger = acct.add_ledger(
        currency: Suma.default_currency,
        name: params[:ledger_name],
        contribution_text: Suma::TranslatedText.create(**params[:contribution_text]),
      )
      vsc = Suma::Vendor::ServiceCategory.find!(name: params[:category_name])
      ledger.add_vendor_service_category(vsc)
      Suma::Payment::BookTransaction.create(
        apply_at: Time.now,
        amount_cents: params[:amount_cents],
        amount_currency: params[:amount_currency],
        originating_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(vsc),
        receiving_ledger: ledger,
        associated_vendor_service_category: vsc,
        memo: Suma::TranslatedText.create(**params[:subsidy_memo]),
      )
    end
  end
end
