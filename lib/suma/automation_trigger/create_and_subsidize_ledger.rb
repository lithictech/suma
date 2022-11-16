# frozen_string_literal: true

require "suma/automation_trigger"

class Suma::AutomationTrigger::CreateAndSubsidizeLedger
  def self.run(instance, event)
    acct = Suma::Payment::Account.find!(event.payload.first)
    instance.db.transaction do
      acct.lock!
      params = instance.parameter.deep_symbolize_keys
      return if acct.ledgers_dataset[name: params[:ledger_name]]
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
