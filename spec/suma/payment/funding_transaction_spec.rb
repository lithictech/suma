# frozen_string_literal: true

require "suma/behaviors"

RSpec.describe "Suma::Payment::FundingTransaction", :db, reset_configuration: Suma::Payment do
  let(:described_class) { Suma::Payment::FundingTransaction }

  describe "start_new" do
    let(:pacct) { Suma::Fixtures.payment_account.create }
    let(:amount) { Money.new(500) }

    it "creates a new transaction to the platform ledger" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, [])
      strategy.set_response(:ready_to_collect_funds?, false)
      xaction = described_class.start_new(pacct, amount:, strategy:, originating_ip: "1.2.3.4")
      expect(xaction).to have_attributes(
        status: "created",
        amount: cost("$5"),
        memo: have_attributes(en: "Transfer to suma"),
        originating_payment_account: be === pacct,
        platform_ledger: be === Suma::Payment::Account.lookup_platform_account.cash_ledger!,
        originated_book_transaction: nil,
        strategy: be_a(Suma::Payment::FakeStrategy),
        originating_ip: IPAddr.new("1.2.3.4"),
      )
    end

    it "tries to collect funds if the strategy says it is ready to collect funds" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, [])
      strategy.set_response(:ready_to_collect_funds?, true)
      strategy.set_response(:collect_funds, true)
      xaction = described_class.start_new(pacct, amount:, strategy:)
      expect(xaction).to have_attributes(status: "collecting")
    end

    it "uses an ACH strategy if originating from a bank account" do
      bank_account = Suma::Fixtures.bank_account.verified.create
      req = stub_request(:post, "https://sandbox.increase.com/transfers/achs").
        to_return(fixture_response("increase/ach_transfer"))

      # Travel to real collection time so we can test collection happens
      xaction = Timecop.travel("2022-10-28T13:00:00-0400") do
        described_class.start_new(pacct, amount:, instrument: bank_account)
      end
      expect(xaction).to have_attributes(
        originating_payment_account: be === pacct,
        platform_ledger: be === Suma::Payment::Account.lookup_platform_account.cash_ledger!,
        strategy: be_a(Suma::Payment::FundingTransaction::IncreaseAchStrategy),
      )
      expect(req).to have_been_made
      expect(xaction.strategy).to have_attributes(originating_bank_account: bank_account)
    end

    it "uses a card strategy if originating from a card" do
      card = Suma::Fixtures.card.member(Suma::Fixtures.member.registered_as_stripe_customer.create).create
      req = stub_request(:post, "https://api.stripe.com/v1/charges").
        to_return(fixture_response("stripe/charge"))
      xaction = described_class.start_new(pacct, amount:, instrument: card, originating_ip: "1.2.3.4")
      expect(xaction).to have_attributes(
        status: "collecting",
        originating_payment_account: be === pacct,
        platform_ledger: be === Suma::Payment::Account.lookup_platform_account.cash_ledger!,
        strategy: be_a(Suma::Payment::FundingTransaction::StripeCardStrategy),
      )
      expect(xaction.strategy).to have_attributes(originating_card: card)
      expect(req).to have_been_made
    end

    it "errors if there is no strategy matching the arguments" do
      fake_instrument = Struct.new(:payment_method_type)
      Suma::Payment.supported_methods = ["specie"]
      expect do
        described_class.start_new(pacct, amount:, instrument: fake_instrument.new(:specie))
      end.to raise_error(described_class::StrategyUnavailable)
    end

    it "errors if the strategy validity check fails" do
      strategy = Suma::Payment::FakeStrategy.create
      strategy.set_response(:check_validity, ["not registered"])
      expect do
        described_class.start_new(pacct, amount:, strategy:)
      end.to raise_error(Suma::Payment::Invalid)
    end

    it "errors if the instrument is not supported" do
      bank_account = Suma::Fixtures.bank_account.verified.create
      Suma::Payment.supported_methods = []
      expect do
        described_class.start_new(pacct, amount:, instrument: bank_account)
      end.to raise_error(Suma::Payment::UnsupportedMethod)
    end
  end

  describe "start_and_transfer" do
    let(:member) { Suma::Fixtures.member.create }
    let(:ledger) { Suma::Payment.ensure_cash_ledger(member) }
    let(:bank_account) { Suma::Fixtures.bank_account.member(member).verified.create }
    let(:category) { Suma::Vendor::ServiceCategory.find_or_create(name: "Cash") }

    it "creates a new funding and book transaction" do
      now = Time.now
      fx = described_class.start_and_transfer(
        member,
        amount: Money.new(500, "USD"),
        instrument: bank_account,
        strategy: Suma::Payment::FakeStrategy.create.not_ready,
        apply_at: now,
      )
      expect(fx).to have_attributes(status: "created")
      expect(member.payment_account.originated_funding_transactions).to contain_exactly(be === fx)
      expect(member.payment_account.cash_ledger.received_book_transactions).to contain_exactly(
        have_attributes(amount: cost("$5"), apply_at: match_time(now)),
      )
      expect(member.payment_account).to have_attributes(total_balance: cost("$5"))
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
        strategy.set_response(:funds_canceled?, false)
        expect(payment).to not_transition_on(:collect_funds)

        strategy.set_response(:funds_cleared?, true)
        expect(payment).to transition_on(:collect_funds).to("cleared")
      end

      it "creates an activity when strategy.collect_funds returns true" do
        strategy.set_response(:ready_to_collect_funds?, true)
        strategy.set_response(:collect_funds, true)
        strategy.set_response(:funds_cleared?, false)
        strategy.set_response(:funds_canceled?, false)
        expect(payment).to transition_on(:collect_funds).to("collecting")
        expect(member.refresh.activities).to have_length(1)

        strategy.set_response(:collect_funds, false)
        expect(payment).to transition_on(:collect_funds).to("collecting")
        expect(member.refresh.activities).to have_length(1)
      end

      it "transitions to review needed if ready to collect funds fails terminally" do
        strategy.set_response(:ready_to_collect_funds?, described_class::CollectFundsFailed.new("nope"))
        expect(payment).to transition_on(:collect_funds).to("needs_review")
      end

      it "transitions to review needed if funds fail to collect" do
        strategy.set_response(:ready_to_collect_funds?, true)
        strategy.set_response(:collect_funds, described_class::CollectFundsFailed.new("nope"))
        expect(payment).to transition_on(:collect_funds).to("needs_review")
        expect(payment.audit_logs.last.messages).to include("Error collecting funds: nope")
      end

      it "transitions to canceled if the funds have been canceled" do
        strategy.set_response(:ready_to_collect_funds?, true)
        strategy.set_response(:funds_cleared?, false)
        strategy.set_response(:funds_canceled?, true)
        strategy.set_response(:collect_funds, false)
        expect(payment).to transition_on(:collect_funds).to("collecting")
        expect(payment).to transition_on(:collect_funds).to("canceled")
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

  describe "refunds" do
    it "can be refunded until it has been fully refunded" do
      card = Suma::Fixtures.card.create

      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create(amount: money("$10"))
      expect(fx).to be_can_refund
      expect(fx).to have_attributes(refundable_amount: cost("$10"))
      Suma::Fixtures::PayoutTransactions.refund_of(fx, card, amount: money("$1"))
      expect(fx).to be_can_refund
      expect(fx).to have_attributes(refundable_amount: cost("$9"))

      Suma::Fixtures::PayoutTransactions.refund_of(fx, card, amount: money("$4"))
      expect(fx).to be_can_refund
      expect(fx).to have_attributes(refundable_amount: cost("$5"))

      Suma::Fixtures::PayoutTransactions.refund_of(fx, card, amount: money("$5"))
      expect(fx).to_not be_can_refund
      expect(fx).to have_attributes(refundable_amount: cost("$0"))
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

  describe "AuditLog" do
    it_behaves_like "an audit log", Suma::Payment::FundingTransaction::AuditLog, :funding_transaction do
      let(:parent) { Suma::Fixtures.funding_transaction.with_fake_strategy.create }
    end
  end
end
