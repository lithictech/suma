# frozen_string_literal: true

RSpec.describe "Suma::AutomationTrigger", :db do
  let(:described_class) { Suma::AutomationTrigger }

  describe Suma::AutomationTrigger::CreateAndSubsidizeLedger do
    let(:at) do
      at = Suma::Fixtures.automation_trigger(
        klass_name: "Suma::AutomationTrigger::CreateAndSubsidizeLedger",
        parameter: {
          ledger_name: "Holidays2022",
          contribution_text: {en: "Ledger En", es: "Ledger Es"},
          category_name: "Test Category",
          amount_cents: 80_00,
          amount_currency: "USD",
          subsidy_memo: {en: "Subsidy En", es: "Subsidy Es"},
        },
      ).create
    end
    let(:pa) { Suma::Fixtures.payment_account.create }

    it "creates and subsidizes the specified ledger", lang: :es do
      Suma::Fixtures.vendor_service_category(name: "Test Category").create
      at.run_with_payload(pa.id)
      expect(pa.ledgers).to contain_exactly(have_attributes(name: "Holidays2022"))
      expect(pa.ledgers.first.received_book_transactions).to contain_exactly(have_attributes(memo_string: "Subsidy Es"))
    end

    it "noops if the ledger exists" do
      Suma::Fixtures.ledger(account: pa).create(name: "Holidays2022")
      at.run_with_payload(pa.id)
      expect(pa.refresh.ledgers.first.received_book_transactions).to be_empty
    end
  end
end
