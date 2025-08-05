# frozen_string_literal: true

require "suma/behaviors"

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
        crediting_book_transaction: nil,
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

  describe "initiate_refund" do
    let(:member) { Suma::Fixtures.member.create }
    let(:ledger) { Suma::Payment.ensure_cash_ledger(member) }
    let(:category) { Suma::Vendor::ServiceCategory.find_or_create(name: "Cash") }
    let(:fx) do
      ba = Suma::Fixtures.bank_account.create(name: "My Savings", account_number: "991234")
      fx = Suma::Fixtures.funding_transaction(amount_cents: 750).with_fake_strategy.create
      fx.strategy.set_response(:originating_instrument_label, ba.simple_label)
      fx
    end
    let(:now) { Time.now }

    it "creates a new payout, book transactions, and sets fields" do
      px = described_class.initiate_refund(
        fx,
        amount: Money.new(500, "USD"),
        strategy: Suma::Payment::FakeStrategy.create.not_ready,
        apply_at: now,
        apply_credit: true,
      )
      expect(px).to have_attributes(
        status: "created",
        refunded_funding_transaction: be === fx,
        crediting_book_transaction: be_present,
        originated_book_transaction: be_present,
        memo: have_attributes(en: "Refund sent to My Savings x-1234"),
      )
      expect(fx.originating_payment_account.originated_payout_transactions).to contain_exactly(be === px)
      expect(px.crediting_book_transaction).to have_attributes(
        amount: cost("$5"),
        apply_at: match_time(now),
        memo: have_attributes(en: "Credit from suma"),
        originating_ledger: px.platform_ledger,
      )
      expect(px.originated_book_transaction).to have_attributes(
        amount: cost("$5"),
        # This should always be applied later than the credit
        apply_at: be > px.crediting_book_transaction.apply_at,
        memo: have_attributes(en: "Refund sent to My Savings x-1234"),
        receiving_ledger: px.platform_ledger,
      )
      # Balance is still $7.50 because the user was credited.
      expect(fx.originating_payment_account).to have_attributes(total_balance: cost("$7.50"))
    end

    it "can optionally not apply a credit" do
      px = described_class.initiate_refund(
        fx,
        amount: Money.new(500, "USD"),
        strategy: Suma::Payment::FakeStrategy.create.not_ready,
        apply_at: now,
        apply_credit: false,
      )
      expect(px).to have_attributes(
        status: "created",
        refunded_funding_transaction: be === fx,
        crediting_book_transaction: be_nil,
        originated_book_transaction: be_present,
        memo: have_attributes(en: "Refund sent to My Savings x-1234"),
      )
      # Balance is still $2.50 because the $5 refund was sent
      expect(fx.originating_payment_account).to have_attributes(total_balance: cost("$2.50"))
    end

    it "errors if the amount is greater than the refundable amount" do
      fx.update(amount: money("$100"))
      Suma::Fixtures::PayoutTransactions.refund_of(fx, Suma::Fixtures.card.create, amount: money("$5"))
      expect do
        described_class.initiate_refund(
          fx,
          amount: money("$100"),
          strategy: Suma::Payment::FakeStrategy.create.not_ready,
          apply_at: now,
          apply_credit: false,
        )
      end.to raise_error(Suma::InvalidPrecondition, /refund cannot be greater than unrefunded amount of \$95\.00/)
    end

    describe "with a strategy of :infer" do
      it "uses a StripeChargeRefundStrategy for a StripeCardStrategy" do
        originating_card = Suma::Fixtures.card.create
        stripe_card_strategy = Suma::Payment::FundingTransaction::StripeCardStrategy.create(
          originating_card:,
          charge_json: {"id" => "ch123"},
        )
        fx.update(fake_strategy: nil, stripe_card_strategy:)

        req = stub_request(:post, "https://api.stripe.com/v1/refunds").
          to_return(json_response(load_fixture_data("stripe/refund")))

        px = described_class.initiate_refund(
          fx,
          amount: Money.new(500, "USD"),
          strategy: :infer,
          apply_at: now,
          apply_credit: false,
        )
        expect(req).to have_been_made
        expect(px).to have_attributes(
          strategy: be_a(Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy),
        )
        expect(px.strategy).to have_attributes(
          stripe_charge_id: "ch123",
          refund_id: "re_1Nispe2eZvKYlo2Cd31jOCgZ",
        )
      end
    end

    describe "using apply_credit of :infer" do
      it "treats apply_credit as false if there are no charges" do
        described_class.initiate_refund(
          fx,
          amount: Money.new(500, "USD"),
          strategy: Suma::Payment::FakeStrategy.create.not_ready,
          apply_at: now,
          apply_credit: :infer,
        )
        expect(fx.originating_payment_account).to have_attributes(total_balance: cost("$2.50"))
      end

      it "treats apply_credit as true if the funding transaction has an associated charge" do
        charge = Suma::Fixtures.charge.create
        charge.add_associated_funding_transaction(fx)
        described_class.initiate_refund(
          fx,
          amount: Money.new(500, "USD"),
          strategy: Suma::Payment::FakeStrategy.create.not_ready,
          apply_at: now,
          apply_credit: :infer,
        )
        expect(fx.originating_payment_account).to have_attributes(total_balance: cost("$7.50"))
      end
    end
  end

  describe "classification" do
    it "is returned based on associated fields" do
      px = described_class.new
      expect(px.classification).to eq("platformpayout")

      px.set(
        originated_book_transaction_id: 1,
        crediting_book_transaction_id: 1,
        refunded_funding_transaction_id: 1,
      )
      expect(px.classification).to eq("refund")

      px.set(
        originated_book_transaction_id: 1,
        crediting_book_transaction_id: nil,
        refunded_funding_transaction_id: 1,
      )
      expect(px.classification).to eq("reversal")

      px.set(
        originated_book_transaction_id: 1,
        crediting_book_transaction_id: nil,
        refunded_funding_transaction_id: nil,
      )
      expect(px.classification).to eq("payout")

      px.set(
        originated_book_transaction_id: nil,
        crediting_book_transaction_id: nil,
        refunded_funding_transaction_id: 1,
      )
      expect(px.classification).to eq("unknown")
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

    it "does not allow the crediting transaction to be set without a payout transaction and refund" do
      payout = Suma::Fixtures.payout_transaction.with_fake_strategy.create
      bx = Suma::Fixtures.book_transaction.create
      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      # Everything can be set
      expect do
        payout.update(
          crediting_book_transaction: bx,
          originated_book_transaction: bx,
          refunded_funding_transaction: fx,
        )
      end.to_not raise_error
      # Only the originated xaction can be set
      expect do
        payout.update(
          crediting_book_transaction: nil,
          originated_book_transaction: bx,
          refunded_funding_transaction: nil,
        )
      end.to_not raise_error
      # Can set the originated xaction and the refund, with no credit
      expect do
        payout.update(
          crediting_book_transaction: nil,
          originated_book_transaction: bx,
          refunded_funding_transaction: fx,
        )
      end.to_not raise_error
      # Cannot set the crediting xaction without the originated
      expect do
        payout.db.transaction(savepoint: true) do
          payout.update(
            crediting_book_transaction: bx,
            originated_book_transaction: nil,
            refunded_funding_transaction: fx,
          )
        end
      end.to raise_error(Sequel::CheckConstraintViolation)
      # Cannot set a crediting xaction without a refund
      payout.refresh
      expect do
        payout.db.transaction(savepoint: true) do
          payout.update(
            crediting_book_transaction: bx,
            originated_book_transaction: bx,
            refunded_funding_transaction: nil,
          )
        end
      end.to raise_error(Sequel::CheckConstraintViolation)
    end
  end

  describe "AuditLog" do
    it_behaves_like "an audit log", Suma::Payment::PayoutTransaction::AuditLog, :payout_transaction do
      let(:parent) { Suma::Fixtures.payout_transaction.with_fake_strategy.create }
    end
  end
end
