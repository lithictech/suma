# frozen_string_literal: true

RSpec.describe "Suma::AutomationTrigger", :db do
  let(:described_class) { Suma::AutomationTrigger }

  describe Suma::AutomationTrigger::CreateAndSubsidizeLedger do
    let(:at) do
      Suma::Fixtures.automation_trigger(
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
      at.run_with_payload(pa.member.id)
      expect(pa.ledgers).to contain_exactly(have_attributes(name: "Holidays2022"))
      expect(pa.ledgers.first.received_book_transactions).to contain_exactly(have_attributes(memo_string: "Subsidy Es"))
    end

    it "noops if the ledger exists" do
      Suma::Fixtures.ledger(account: pa).create(name: "Holidays2022")
      at.run_with_payload(pa.member.id)
      expect(pa.refresh.ledgers.first.received_book_transactions).to be_empty
    end

    describe "when constraints are set on the trigger" do
      let(:constraint) { Suma::Fixtures.eligibility_constraint(name: "Special Person").create }
      before(:each) do
        at.parameter = at.parameter.merge("verified_constraint_name" => constraint.name)
        at.save_changes.refresh
        Suma::Fixtures.vendor_service_category(name: "Test Category").create
      end

      it "noops if the member does not satisfy constraints" do
        pa.member.replace_eligibility_constraint(constraint, "pending")
        at.run_with_payload(pa.member.id)
        expect(pa.ledgers).to be_empty
      end

      it "creates and subsidizes the ledger if it does satisfy constraints" do
        pa.member.replace_eligibility_constraint(constraint, "verified")
        at.run_with_payload(pa.member.id)
        expect(pa.ledgers).to contain_exactly(have_attributes(name: "Holidays2022"))
      end

      it "handles an array of constraint names" do
        at.parameter = at.parameter.merge("verified_constraint_name" => [constraint.name])
        at.save_changes.refresh
        pa.member.replace_eligibility_constraint(constraint, "verified")
        at.run_with_payload(pa.member.id)
        expect(pa.ledgers).to contain_exactly(have_attributes(name: "Holidays2022"))
      end
    end
  end

  describe Suma::AutomationTrigger::AutoOnboard do
    let(:at) do
      Suma::Fixtures.automation_trigger(klass_name: "Suma::AutomationTrigger::AutoOnboard").create
    end

    it "verifies the member" do
      member = Suma::Fixtures.member.create
      expect(member.refresh).to_not be_onboarding_verified
      at.run_with_payload(member.id)
      expect(member.refresh).to be_onboarding_verified
    end
  end

  describe Suma::AutomationTrigger::FundingTransactionMatch do
    let(:at) do
      Suma::Fixtures.automation_trigger(
        klass_name: "Suma::AutomationTrigger::FundingTransactionMatch",
        parameter: {
          ledger_name: "Tester",
          subsidy_memo: {en: "Subsidy En", es: "Subsidy Es"},
        },
      ).create
    end
    let(:funding_xaction) { Suma::Fixtures.funding_transaction.with_fake_strategy.create(amount_cents: 1000) }
    let(:payment_account) { funding_xaction.originating_payment_account }
    let!(:vsc) { Suma::Fixtures.vendor_service_category(name: "Test Category").create }
    let!(:ledger) do
      led = Suma::Fixtures.ledger.create(name: "Tester", account: payment_account)
      led.add_vendor_service_category(vsc)
      led
    end

    it "subsidizes the specified ledger", lang: :es do
      at.run_with_payload(funding_xaction.id)
      expect(ledger.refresh.received_book_transactions).to contain_exactly(
        have_attributes(
          associated_vendor_service_category: be === vsc,
          memo_string: "Subsidy Es",
          amount: cost("$10"),
        ),
      )
    end

    it "can subsidize with a ratio and max" do
      at.update(parameter: at.parameter.merge(match_ratio: 2, max_cents: 1500))
      at.run_with_payload(funding_xaction.id)
      expect(ledger.refresh.received_book_transactions).to contain_exactly(
        have_attributes(
          amount: cost("$15"),
        ),
      )
    end

    it "does not subsidize funding transactions already used in a charge" do
      charge = Suma::Fixtures.charge.create
      charge.add_associated_funding_transaction(funding_xaction)
      at.run_with_payload(funding_xaction.id)
      expect(ledger.refresh.received_book_transactions).to be_empty
    end

    it "handles existing subsidy on the ledger and only goes up to max_cents" do
      at.update(parameter: at.parameter.merge(max_cents: 1500))
      at.run_with_payload(funding_xaction.id)
      expect(ledger.refresh.received_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$10")),
      )

      second_fx = Suma::Fixtures.funding_transaction.with_fake_strategy.
        create(originating_payment_account: payment_account, amount_cents: 1000)
      at.run_with_payload(second_fx.id)
      expect(ledger.refresh.received_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$10")),
        have_attributes(amount: cost("$5")),
      )

      noop_fx = Suma::Fixtures.funding_transaction.with_fake_strategy.
        create(originating_payment_account: payment_account, amount_cents: 1000)
      at.run_with_payload(noop_fx.id)
      expect(ledger.refresh.received_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$10")),
        have_attributes(amount: cost("$5")),
      )
    end

    describe "when constraints are set on the trigger" do
      let(:constraint) { Suma::Fixtures.eligibility_constraint(name: "Special Person").create }
      let(:member) { funding_xaction.originating_payment_account.member }
      before(:each) do
        at.parameter = at.parameter.merge("verified_constraint_name" => constraint.name)
        at.save_changes.refresh
      end

      it "noops if the member does not satisfy constraints" do
        member.replace_eligibility_constraint(constraint, "pending")
        at.run_with_payload(funding_xaction.id)
        expect(ledger.refresh.received_book_transactions).to be_empty
      end

      it "creates and subsidizes the ledger if it does satisfy constraints" do
        member.replace_eligibility_constraint(constraint, "verified")
        at.run_with_payload(funding_xaction.id)
        expect(ledger.refresh.received_book_transactions).to contain_exactly(have_attributes(amount: cost("$10")))
      end
    end
  end
end
