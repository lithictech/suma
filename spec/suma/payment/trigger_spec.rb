# frozen_string_literal: true

RSpec.describe "Suma::Payment::Trigger", :db do
  let(:described_class) { Suma::Payment::Trigger }
  let(:apply_at) { Time.now }
  let(:context) { Suma::Payment::CalculationContext.new(apply_at) }

  it "can be fixtured" do
    expect(Suma::Fixtures.payment_trigger.create).to be_a(described_class)
    expect(Suma::Fixtures.payment_trigger.memo("hi").create).to have_attributes(memo: have_attributes(en: "hi"))
  end

  it "knows its programs" do
    pr = Suma::Fixtures.program.create
    tr = Suma::Fixtures.payment_trigger.matching.with_programs(pr).create
    expect(tr.programs).to contain_exactly(be === pr)
    expect(pr.payment_triggers).to contain_exactly(be === tr)
  end

  describe "associations" do
    it "knows its program enrollments" do
      e1 = Suma::Fixtures.program_enrollment.create
      e2 = Suma::Fixtures.program_enrollment.create
      e3 = Suma::Fixtures.program_enrollment.create

      o = Suma::Fixtures.payment_trigger.create
      o.add_program(e1.program)
      o.add_program(e2.program)
      expect(o.program_enrollments).to have_same_ids_as(e1, e2)
    end
  end

  describe "match multiplier math" do
    it "can calculate a payer/match fractions for what the customer vs. platform is paying" do
      tr = described_class.new

      tr.match_multiplier = 0
      expect(tr).to have_attributes(payer_fraction: 1, match_fraction: 0)
      tr.match_multiplier = 1
      expect(tr).to have_attributes(payer_fraction: 0.5, match_fraction: 0.5)
      tr.match_multiplier = 3
      expect(tr).to have_attributes(payer_fraction: 0.25, match_fraction: 0.75)
      tr.match_multiplier = 9
      expect(tr).to have_attributes(payer_fraction: 0.10, match_fraction: 0.90)

      tr.match_multiplier = 0.5
      expect(tr.payer_fraction.round(2)).to eq(0.67)
      expect(tr.match_fraction.round(2)).to eq(0.33)

      tr.match_multiplier = 0.10
      expect(tr.payer_fraction.round(2)).to eq(0.91)
      expect(tr.match_fraction.round(2)).to eq(0.09)
    end

    it "can set the match multiplier from a payer and match fractions" do
      tr = described_class.new
      tr.match_fraction = 0.2
      expect(tr).to have_attributes(payer_fraction: 0.8, match_multiplier: 0.25)
    end

    it "can set the match multiplier from a payer fraction" do
      tr = described_class.new
      tr.payer_fraction = 0.8
      expect(tr).to have_attributes(match_fraction: 0.2, match_multiplier: 0.25)
    end
  end

  describe "funding_plan" do
    let(:account) { Suma::Fixtures.payment_account.create }
    let(:active_as_of) { apply_at }

    it "returns an empty plan if there are no triggers" do
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
      expect(plan.steps).to be_empty
    end

    it "uses a plan step for each matching trigger" do
      t1 = Suma::Fixtures.payment_trigger.create
      t2 = Suma::Fixtures.payment_trigger.create
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
      expect(plan.steps).to contain_exactly(
        have_attributes(trigger: be === t1),
        have_attributes(trigger: be === t2),
      )
    end

    it "considers only active triggers" do
      t = Suma::Fixtures.payment_trigger.create
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
      expect(plan.steps).to have_length(1)

      t.update(active_during_end: 1.minute.ago)
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
      expect(plan.steps).to be_empty
    end

    it "reuses an existing ledger with the trigger receiving ledger name" do
      receiving = Suma::Fixtures.ledger(account:).create(name: "testledger")
      t = Suma::Fixtures.payment_trigger.create(receiving_ledger_name: "testledger")
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
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
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
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

    describe "when no the trigger has no programs" do
      it "does not exclude based on programs" do
        t = Suma::Fixtures.payment_trigger.matching.create
        plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
        expect(plan.steps).to contain_exactly(
          have_attributes(trigger: t),
        )
      end
    end

    describe "when the trigger is in a program" do
      let!(:program) { Suma::Fixtures.program.create }
      let!(:tr) { Suma::Fixtures.payment_trigger.matching.with_programs(program).no_max.create }

      it "excludes the trigger if the subject does not have an active enrollment in an overlapping program" do
        unenrolled = Suma::Fixtures.program_enrollment.unenrolled.create(member: account.member, program:)
        different_program = Suma::Fixtures.program_enrollment.create(member: account.member)
        plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
        expect(plan.steps).to be_empty
      end

      it "includes the trigger if the subject has an active enrollment in the trigger program" do
        Suma::Fixtures.program_enrollment.create(member: account.member, program:)
        plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$10"))
        expect(plan.steps).to contain_exactly(have_attributes(trigger: tr))
      end
    end

    describe "max subsidy" do
      it "treats 0 cents as no maximum" do
        t = Suma::Fixtures.payment_trigger.matching.up_to(money("$0")).create
        plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$100"))
        expect(plan.steps).to contain_exactly(
          have_attributes(amount: money("$100"), trigger: t),
        )
      end

      it "will not subsidize a ledger balance above the maximum" do
        t = Suma::Fixtures.payment_trigger.matching.up_to(money("$20")).create
        plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$100"))
        expect(plan.steps).to contain_exactly(
          have_attributes(amount: money("$20"), trigger: t),
        )
      end

      it "takes previous trigger executions into account" do
        t = Suma::Fixtures.payment_trigger.matching.up_to(money("$20")).create
        receiving = t.ensure_receiving_ledger(account)
        to_same_ledger = Suma::Payment::Trigger::Execution.create(
          trigger: t,
          book_transaction: Suma::Fixtures.book_transaction.to(receiving).create(amount: money("$7")),
        )
        to_diff_ledger = Suma::Payment::Trigger::Execution.create(
          trigger: t,
          book_transaction: Suma::Fixtures.book_transaction.create(amount: money("$5")),
        )
        unassociated_book_xaction = Suma::Fixtures.book_transaction.to(receiving).create(amount: money("$0.50"))

        plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$100"))
        expect(plan.steps).to contain_exactly(
          have_attributes(amount: money("$13"), trigger: t),
        )
      end
    end

    it "applies the match ratio to the planned amount" do
      t = Suma::Fixtures.payment_trigger.matching(0.5).create
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$15"))
      expect(plan.steps).to contain_exactly(
        have_attributes(amount: money("$7.50"), trigger: t),
      )
    end

    it "rounds the match ratio to the nearest cent" do
      t = Suma::Fixtures.payment_trigger.matching(0.3333).create
      plan = described_class.gather(account, active_as_of:).funding_plan(context, money("$3.33"))
      expect(plan.steps).to contain_exactly(
        have_attributes(amount: money("$1.11"), trigger: t),
      )
    end
  end

  describe "Collection" do
    let(:account) { Suma::Fixtures.payment_account.create }
    let(:active_as_of) { apply_at }

    it "knows triggers that can contribute to an item with vendor service categories" do
      cata = Suma::Fixtures.vendor_service_category.create
      catb = Suma::Fixtures.vendor_service_category.create(parent: cata)
      catc = Suma::Fixtures.vendor_service_category.create(parent: catb)

      vs = Suma::Fixtures.vendor_service.with_categories(catb).create

      tra = Suma::Fixtures.payment_trigger.matching(1).create
      tra.originating_ledger.add_vendor_service_category(cata)
      trb = Suma::Fixtures.payment_trigger.matching(11).create
      trb.originating_ledger.add_vendor_service_category(catb)
      trc = Suma::Fixtures.payment_trigger.matching(111).create
      trc.originating_ledger.add_vendor_service_category(catc)

      coll = described_class.gather(account, active_as_of:)
      triggers = coll.potentially_contributing_to(vs)
      expect(triggers).to have_same_ids_as(tra, trb)

      sumtr = described_class.summed(triggers)
      expect(sumtr).to have_attributes(match_multiplier: 12)
      expect { sumtr.save_changes }.to raise_error(/can't save frozen object/)

      expect(coll.potentially_contributing_to(vs, summed: true)).to contain_exactly(
        have_attributes(match_multiplier: 12),
      )
    end
  end

  describe "FundingPlan" do
    describe "apply" do
      let(:account) { Suma::Fixtures.payment_account.create }

      it "creates book transactions and related trigger executions" do
        t = Suma::Fixtures.payment_trigger.matching(0.5).create
        plan = described_class.gather(account, active_as_of: apply_at).funding_plan(context, money("$15"))
        now = 1.hour.ago
        executions = plan.execute(ledgers: account.ledgers, at: now)
        expect(executions).to have_length(1)
        expect(executions[0]).to have_attributes(
          trigger: be === t,
          book_transaction: have_attributes(
            apply_at: match_time(now),
            amount: money("$7.50"),
            originating_ledger: be === t.originating_ledger,
            receiving_ledger: account.ledgers(reload: true).first,
            triggered_by: be === executions[0],
          ),
        )
      end

      it "does not execute the trigger if the trigger ledger is not passed in" do
        Suma::Fixtures.payment_trigger.create
        Suma::Fixtures.payment_trigger.create
        plan = described_class.gather(account, active_as_of: apply_at).funding_plan(context, money("$15"))
        expect(plan.steps).to have_length(2)
        expect(account.ledgers).to have_length(2)
        step = plan.steps.first
        executions = plan.execute(ledgers: [step.receiving_ledger], at: Time.now)
        expect(executions).to have_length(1)
        expect(executions[0]).to have_attributes(
          trigger: be === step.trigger,
          book_transaction: have_attributes(
            receiving_ledger: be === step.receiving_ledger,
          ),
        )
      end
    end
  end

  describe "#subdivide" do
    let(:tr) do
      Suma::Fixtures.payment_trigger.create(
        label: "MyTrigger",
        active_during: Time.parse("2025-01-01T00:00:00Z")..Time.parse("2025-01-02T00:00:00Z"),
      )
    end

    it "can subdivide evenly" do
      created = tr.subdivide(amount: 6, unit: :hour)
      expect(created).to have_length(4)
      expect(created.first).to be === tr
      expect(created).to match_array(
        [
          have_attributes(
            label: "MyTrigger (hours 1-6)",
            active_during_begin: match_time("2025-01-01T00:00:00Z"),
            active_during_end: match_time("2025-01-01T06:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hours 7-12)",
            active_during_begin: match_time("2025-01-01T06:00:00Z"),
            active_during_end: match_time("2025-01-01T12:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hours 13-18)",
            active_during_begin: match_time("2025-01-01T12:00:00Z"),
            active_during_end: match_time("2025-01-01T18:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hours 19-24)",
            active_during_begin: match_time("2025-01-01T18:00:00Z"),
            active_during_end: match_time("2025-01-02T00:00:00Z"),
          ),
        ],
      )
    end

    it "returns [self] with an interval larger than the active_during" do
      created = tr.subdivide(amount: 31, unit: :hour)
      expect(created).to contain_exactly(be === tr)
      expect(created.first).to have_attributes(
        label: "MyTrigger",
        active_during_begin: match_time("2025-01-01T00:00:00Z"),
        active_during_end: match_time("2025-01-02T00:00:00Z"),
      )
    end

    it "returns [self] with an interval equal to active_during" do
      created = tr.subdivide(amount: 24, unit: :hour)
      expect(created).to contain_exactly(be === tr)
      expect(created.first).to have_attributes(
        label: "MyTrigger",
        active_during_begin: match_time("2025-01-01T00:00:00Z"),
        active_during_end: match_time("2025-01-02T00:00:00Z"),
      )
    end

    it "can subdivide with an interval that does not divide evenly into the active_during" do
      created = tr.subdivide(amount: 13, unit: :hour)
      expect(created).to have_length(2)
      expect(created.first).to be === tr
      expect(created).to match_array(
        [
          have_attributes(
            label: "MyTrigger (hours 1-13)",
            active_during_begin: match_time("2025-01-01T00:00:00Z"),
            active_during_end: match_time("2025-01-01T13:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hours 14-26)",
            active_during_begin: match_time("2025-01-01T13:00:00Z"),
            active_during_end: match_time("2025-01-02T00:00:00Z"),
          ),
        ],
      )
    end

    it "uses a singular label when the amount is 1" do
      tr.update(active_during_end: Time.parse("2025-01-01T04:00:00Z"))
      created = tr.subdivide(amount: 1, unit: :hour)
      expect(created).to have_length(4)
      expect(created.first).to be === tr
      expect(created).to match_array(
        [
          have_attributes(
            label: "MyTrigger (hour 1)",
            active_during_begin: match_time("2025-01-01T00:00:00Z"),
            active_during_end: match_time("2025-01-01T01:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hour 2)",
            active_during_begin: match_time("2025-01-01T01:00:00Z"),
            active_during_end: match_time("2025-01-01T02:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hour 3)",
            active_during_begin: match_time("2025-01-01T02:00:00Z"),
            active_during_end: match_time("2025-01-01T03:00:00Z"),
          ),
          have_attributes(
            label: "MyTrigger (hour 4)",
            active_during_begin: match_time("2025-01-01T03:00:00Z"),
            active_during_end: match_time("2025-01-01T04:00:00Z"),
          ),
        ],
      )
    end
  end
end
