# frozen_string_literal: true

RSpec.describe "Suma::Payment::FundingTransaction", :db do
  let(:described_class) { Suma::Payment::FundingTransaction }

  describe "start_new" do
    let(:pacct) { Suma::Fixtures.payment_account.create }

    it "creates a new transaction to the platform ledger" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, [])
      xaction = described_class.start_new(pacct, amount: Money.new(500), strategy:)
      expect(xaction).to have_attributes(
        status: "created",
        amount: cost("$5"),
        memo: "Transfer to Suma App",
        originating_payment_account: be === pacct,
        platform_ledger: be === Suma::Payment::Account.lookup_platform_account.cash_ledger!,
        originated_book_transaction: nil,
        strategy: be_a(Suma::Payment::FakeStrategy),
      )
    end

    it "uses an ACH strategy if originating from a bank account" do
      bank_account = Suma::Fixtures.bank_account.verified.create
      xaction = described_class.start_new(pacct, amount: Money.new(500), bank_account:)
      expect(xaction).to have_attributes(
        originating_payment_account: be === pacct,
        platform_ledger: be === Suma::Payment::Account.lookup_platform_account.cash_ledger!,
        strategy: be_a(Suma::Payment::FundingTransaction::IncreaseAchStrategy),
      )
      expect(xaction.strategy).to have_attributes(originating_bank_account: bank_account)
    end

    it "errors if there is no strategy matching the arguments" do
      expect do
        described_class.start_new(pacct, amount: Money.new(500))
      end.to raise_error(described_class::StrategyUnavailable)
    end

    it "errors if the strategy validity check fails" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, ["not registered"])
      expect do
        described_class.start_new(pacct, amount: Money.new(500), strategy:)
      end.to raise_error(Suma::Payment::Invalid)
    end
  end

  describe "state machine" do
    let(:strategy) { Suma::Payment::FakeStrategy.create }
    let(:payment) { Suma::Fixtures.funding_transaction.with_fake_strategy(strategy).create }
    let(:member) { payment.originating_payment_account.member }

    describe "collect_funds" do
      it "processes to collecting when ready to collect funds, and cleared when funds have cleared" do
        strategy.set_response(:ready_to_collect_funds?, false)
        expect(payment).to have_attributes(status: "created")
        expect(payment).to not_transition_on(:collect_funds)

        strategy.set_response(:ready_to_collect_funds?, true)
        strategy.set_response(:collect_funds, true)
        expect(payment).to transition_on(:collect_funds).to("collecting")
        strategy.set_response(:funds_cleared?, false)
        expect(payment).to not_transition_on(:collect_funds)

        strategy.set_response(:funds_cleared?, true)
        expect(payment).to transition_on(:collect_funds).to("cleared")
      end

      it "creates an activity when strategy.collect_funds returns true" do
        strategy.set_response(:ready_to_collect_funds?, true)
        strategy.set_response(:collect_funds, true)
        strategy.set_response(:funds_cleared?, false)
        expect(payment).to transition_on(:collect_funds).to("collecting")
        expect(member.refresh.activities).to have_length(1)

        strategy.set_response(:collect_funds, false)
        expect(payment).to transition_on(:collect_funds).to("collecting")
        expect(member.refresh.activities).to have_length(1)
      end

      it "transition to review needed if ready to collect funds fails terminally" do
        strategy.set_response(:ready_to_collect_funds?, described_class::CollectFundsFailed.new("nope"))
        expect(payment).to transition_on(:collect_funds).to("needs_review")
      end

      it "transition to review needed if funds fail to collect" do
        strategy.set_response(:ready_to_collect_funds?, true)
        strategy.set_response(:collect_funds, described_class::CollectFundsFailed.new("nope"))
        expect(payment).to transition_on(:collect_funds).to("needs_review")
        expect(payment.audit_logs.last.messages).to include("Error collecting funds: nope")
      end
    end

    describe "cancel" do
      it "transitions to canceled" do
        expect(payment).to transition_on(:cancel).to("canceled")
        expect(payment).to not_transition_on(:cancel)

        expect(payment).to transition_on(:put_into_review).with("hi").to("needs_review")
        expect(payment).to transition_on(:cancel).to("canceled")
      end
    end

    describe "put_into_review" do
      it "uses the reason and message" do
        expect(payment).to transition_on(:put_into_review).with("mymessage", reason: "re").to("needs_review")
        expect(payment.audit_logs.last).to have_attributes(reason: "re", messages: ["mymessage"])
      end

      it "formats the exception into the message and uses the class as the reason" do
        e = RuntimeError.new("hello")
        expect(payment).to transition_on(:put_into_review).with("mymessage", exception: e).to("needs_review")
        expect(payment.audit_logs.last).to have_attributes(reason: "RuntimeError", messages: ["mymessage: hello"])
      end

      it "uses the wrapped exception type as the reason" do
        e = described_class::CollectFundsFailed.new("hello", RuntimeError.new("bye"))
        expect(payment).to transition_on(:put_into_review).with("mymessage", exception: e).to("needs_review")
        expect(payment.audit_logs.last).to have_attributes(reason: "RuntimeError", messages: ["mymessage: hello: bye"])
      end
    end
  end

  describe "timestamp_accessors" do
    let(:strategy) { Suma::Payment::FakeStrategy.create }
    let(:payment) { Suma::Fixtures.funding_transaction.with_fake_strategy(strategy).create }

    it "has them set by events" do
      strategy.set_response(:ready_to_collect_funds?, true)
      strategy.set_response(:collect_funds, false)
      strategy.set_response(:funds_cleared?, true)

      t = trunc_time(Time.now)
      Timecop.freeze(t + 1) { expect(payment).to transition_on(:collect_funds).to("collecting") }
      Timecop.freeze(t + 2) { expect(payment).to transition_on(:collect_funds).to("cleared") }
      expect(payment.funds_collecting_at).to eq(t + 1)
      expect(payment.funds_cleared_at).to eq(t + 2)
    end
  end

  describe "hooks" do
    it "saves strategy changes after save" do
      payment = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      payment.strategy.responses = {"x" => "y"}
      # We don't have a changed column, so save_changes won't trigger it
      payment.save # rubocop:disable Sequel/SaveChanges
      expect(payment.refresh.strategy.responses).to eq({"x" => "y"})
    end
  end

  describe "validations" do
    it "requires a strategy" do
      payment = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      expect { payment.save_changes }.to_not raise_error
      expect { payment.update(fake_strategy: nil) }.to raise_error(/strategy is not available/i)
    end
  end
end
