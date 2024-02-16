# frozen_string_literal: true

RSpec.describe "Suma::Payment::Trigger", :db do
  let(:described_class) { Suma::Payment::Trigger }
  let(:apply_at) { Time.now }

  it "can be fixtured" do
    pa = Suma::Fixtures.payment_trigger.create
    expect(pa).to be_a(described_class)
  end

  it "knows its constraints" do
    con = Suma::Fixtures.eligibility_constraint.create
    tr = Suma::Fixtures.payment_trigger.matching.with_constraints(con).create
    expect(tr.eligibility_constraints).to contain_exactly(be === con)
    expect(con.payment_triggers).to contain_exactly(be === tr)
  end

  describe "plan" do
    let(:account) { Suma::Fixtures.payment_account.create }

    it "returns an empty plan if there are no triggers" do
      plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
      expect(plan.steps).to be_empty
    end

    it "uses a plan step for each matching trigger" do
      t1 = Suma::Fixtures.payment_trigger.create
      t2 = Suma::Fixtures.payment_trigger.create
      plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
      expect(plan.steps).to contain_exactly(
        have_attributes(trigger: be === t1),
        have_attributes(trigger: be === t2),
      )
    end

    it "considers only active triggers" do
      t = Suma::Fixtures.payment_trigger.create
      plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
      expect(plan.steps).to have_length(1)

      t.update(active_during_end: 1.minute.ago)
      plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
      expect(plan.steps).to be_empty
    end

    it "reuses an existing ledger with the trigger receiving ledger name" do
      receiving = Suma::Fixtures.ledger(account:).create(name: "testledger")
      t = Suma::Fixtures.payment_trigger.create(receiving_ledger_name: "testledger")
      plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
      expect(plan.steps).to contain_exactly(
        have_attributes(
          receiving_ledger: receiving,
          trigger: t,
        ),
      )
      expect(account.refresh.ledgers).to contain_exactly(be === receiving)
    end

    it "creates and sets up the target ledger if the subject does not have one" do
      vsc = Suma::Fixtures.vendor_service_category.create
      originating_ledger = Suma::Fixtures.ledger.with_categories(vsc).create
      t = Suma::Fixtures.payment_trigger.create(originating_ledger:, receiving_ledger_name: "testledger")
      plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
      expect(plan.steps).to contain_exactly(
        have_attributes(trigger: t),
      )
      expect(account.ledgers).to contain_exactly(
        have_attributes(
          name: "testledger",
          contribution_text: be === t.receiving_ledger_contribution_text,
          vendor_service_categories: contain_exactly(be === vsc),
        ),
      )
      expect(plan.steps.first).to have_attributes(
        receiving_ledger: be === account.ledgers.first,
      )
    end

    describe "when no constraints are set" do
      it "does not exclude based on constraints" do
        t = Suma::Fixtures.payment_trigger.matching.create
        plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
        expect(plan.steps).to contain_exactly(
          have_attributes(trigger: t),
        )
      end
    end

    describe "when constraints are set" do
      let!(:constraint) { Suma::Fixtures.eligibility_constraint.create }
      let!(:tr) { Suma::Fixtures.payment_trigger.matching.with_constraints(constraint).create }

      it "excludes the trigger if the subject that does not satisfy constraints" do
        account.member.replace_eligibility_constraint(constraint, "pending")
        account.member.replace_eligibility_constraint(Suma::Fixtures.eligibility_constraint.create, "verified")
        plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
        expect(plan.steps).to be_empty
      end

      it "includes the trigger if the subject satisfies constraints" do
        account.member.replace_eligibility_constraint(constraint, "verified")
        plan = described_class.gather(account, apply_at:).funding_plan(money("$10"))
        expect(plan.steps).to contain_exactly(have_attributes(trigger: tr))
      end
    end

    describe "when max subsidy cents are set" do
      it "will not subsidize a ledger balance above the maximum" do
        t = Suma::Fixtures.payment_trigger.matching.up_to(money("$20")).create
        plan = described_class.gather(account, apply_at:).funding_plan(money("$100"))
        expect(plan.steps).to contain_exactly(
          have_attributes(amount: money("$20"), trigger: t),
        )
      end

      it "takes existing ledger balance into account" do
        t = Suma::Fixtures.payment_trigger.matching.up_to(money("$20")).create
        receiving = t.ensure_receiving_ledger(account)
        Suma::Fixtures.book_transaction.to(receiving).create(amount: money("$7"))
        plan = described_class.gather(account, apply_at:).funding_plan(money("$100"))
        expect(plan.steps).to contain_exactly(
          have_attributes(amount: money("$13"), trigger: t),
        )
      end
    end

    it "applies the match ratio to the planned amount" do
      t = Suma::Fixtures.payment_trigger.matching(0.5).create
      plan = described_class.gather(account, apply_at:).funding_plan(money("$15"))
      expect(plan.steps).to contain_exactly(
        have_attributes(amount: money("$7.50"), trigger: t),
      )
    end

    it "rounds the match ratio to the nearest cent" do
      t = Suma::Fixtures.payment_trigger.matching(0.3333).create
      plan = described_class.gather(account, apply_at:).funding_plan(money("$3.33"))
      expect(plan.steps).to contain_exactly(
        have_attributes(amount: money("$1.11"), trigger: t),
      )
    end
  end
end
