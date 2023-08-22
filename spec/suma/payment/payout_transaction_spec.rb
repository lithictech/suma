# frozen_string_literal: true

RSpec.describe "Suma::Payment::PayoutTransaction", :db, reset_configuration: Suma::Payment do
  let(:described_class) { Suma::Payment::PayoutTransaction }

  describe "start_new" do
    let(:pacct) { Suma::Fixtures.payment_account.create }
    let(:amount) { Money.new(500) }

    it "creates a new payout transaction from the ledger" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, [])
      strategy.set_response(:ready_to_send_funds?, false)
      xaction = described_class.start_new(pacct, amount:, strategy:)
      expect(xaction).to have_attributes(
        status: "created",
        amount: cost("$5"),
        memo: have_attributes(en: "Transfer from suma"),
        originating_payment_account: be === pacct,
        platform_ledger: be === Suma::Payment::Account.lookup_platform_account.cash_ledger!,
        originated_book_transaction: nil,
        strategy: be_a(Suma::Payment::FakeStrategy),
      )
    end

    it "tries to send funds if the strategy says it is ready to send funds" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, [])
      strategy.set_response(:ready_to_send_funds?, true)
      strategy.set_response(:send_funds, true)
      xaction = described_class.start_new(pacct, amount:, strategy:)
      expect(xaction).to have_attributes(status: "sending")
    end

    it "errors if the strategy validity check fails" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, ["not registered"])
      expect do
        described_class.start_new(pacct, amount:, strategy:)
      end.to raise_error(Suma::Payment::Invalid)
    end
  end

  describe "start_and_transfer" do
    let(:member) { Suma::Fixtures.member.create }
    let(:ledger) { Suma::Payment.ensure_cash_ledger(member) }
    let(:category) { Suma::Vendor::ServiceCategory.find_or_create(name: "Cash") }

    it "creates a new payout and book transaction" do
      now = Time.now
      px = described_class.start_and_transfer(
        ledger,
        amount: Money.new(500, "USD"),
        vendor_service_category: category,
        strategy: Suma::Payment::FakeStrategy.create.not_ready,
        apply_at: now,
      )
      expect(px).to have_attributes(status: "created")
      expect(member.payment_account.originated_payout_transactions).to contain_exactly(be === px)
      expect(member.payment_account.cash_ledger.originated_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$5"), apply_at: match_time(now)),
      )
      expect(member.payment_account).to have_attributes(total_balance: cost("-$5"))
    end
  end

  describe "state machine" do
    let(:strategy) { Suma::Payment::FakeStrategy.create }
    let(:payment) { Suma::Fixtures.payout_transaction.with_fake_strategy(strategy).create }
    let(:member) { payment.originating_payment_account.member }

    describe "send_funds" do
      it "processes to sending when ready to send funds, and settles when funds have settled" do
        strategy.set_response(:ready_to_send_funds?, false)
        expect(payment).to have_attributes(status: "created")
        expect(payment).to not_transition_on(:send_funds)

        strategy.set_response(:ready_to_send_funds?, true)
        strategy.set_response(:send_funds, true)
        expect(payment).to transition_on(:send_funds).to("sending")
        strategy.set_response(:funds_settled?, false)
        expect(payment).to not_transition_on(:send_funds)

        strategy.set_response(:funds_settled?, true)
        expect(payment).to transition_on(:send_funds).to("settled")
      end

      it "creates an activity when strategy.send_funds returns true" do
        strategy.set_response(:ready_to_send_funds?, true)
        strategy.set_response(:send_funds, true)
        strategy.set_response(:funds_settled?, false)
        expect(payment).to transition_on(:send_funds).to("sending")
        expect(member.refresh.activities).to have_length(1)

        strategy.set_response(:send_funds, false)
        expect(payment).to transition_on(:send_funds).to("sending")
        expect(member.refresh.activities).to have_length(1)
      end

      it "transition to review needed if ready to collect funds fails terminally" do
        strategy.set_response(:ready_to_send_funds?, described_class::SendFundsFailed.new("nope"))
        expect(payment).to transition_on(:send_funds).to("needs_review")
      end

      it "transition to review needed if funds fail to collect" do
        strategy.set_response(:ready_to_send_funds?, true)
        strategy.set_response(:send_funds, described_class::SendFundsFailed.new("nope"))
        expect(payment).to transition_on(:send_funds).to("needs_review")
        expect(payment.audit_logs.last.messages).to include("Error sending funds: nope")
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
        e = described_class::SendFundsFailed.new("hello", RuntimeError.new("bye"))
        expect(payment).to transition_on(:put_into_review).with("mymessage", exception: e).to("needs_review")
        expect(payment.audit_logs.last).to have_attributes(reason: "RuntimeError", messages: ["mymessage: hello: bye"])
      end
    end
  end

  describe "timestamp_accessors" do
    let(:strategy) { Suma::Payment::FakeStrategy.create }
    let(:payment) { Suma::Fixtures.payout_transaction.with_fake_strategy(strategy).create }

    it "has them set by events" do
      strategy.set_response(:ready_to_send_funds?, true)
      strategy.set_response(:send_funds, false)
      strategy.set_response(:funds_settled?, true)

      t = trunc_time(Time.now)
      Timecop.freeze(t + 1) { expect(payment).to transition_on(:send_funds).to("sending") }
      Timecop.freeze(t + 2) { expect(payment).to transition_on(:send_funds).to("settled") }
      expect(payment.funds_sending_at).to eq(t + 1)
      expect(payment.funds_settled_at).to eq(t + 2)
    end
  end

  describe "hooks" do
    it "saves strategy changes after save" do
      payment = Suma::Fixtures.payout_transaction.with_fake_strategy.create
      payment.strategy.responses = {"x" => "y"}
      # We don't have a changed column, so save_changes won't trigger it
      payment.save # rubocop:disable Sequel/SaveChanges
      expect(payment.refresh.strategy.responses).to eq({"x" => "y"})
    end
  end

  describe "validations" do
    it "requires a strategy" do
      payment = Suma::Fixtures.payout_transaction.with_fake_strategy.create
      expect { payment.save_changes }.to_not raise_error
      expect { payment.update(fake_strategy: nil) }.to raise_error(/strategy is not available/i)
    end
  end
end
