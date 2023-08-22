# frozen_string_literal: true

require "state_machines"

require "suma/admin_linked"
require "suma/state_machine"
require "suma/payment"
require "suma/payment/external_transaction"

class Suma::Payment::PayoutTransaction < Suma::Postgres::Model(:payment_payout_transactions)
  include Suma::AdminLinked
  include Suma::Payment::ExternalTransaction

  class SendFundsFailed < Suma::StateMachine::FailedTransition; end

  plugin :state_machine
  plugin :timestamps
  plugin :money_fields, :amount
  plugin :translated_text, :memo, Suma::TranslatedText

  many_to_one :platform_ledger, class: "Suma::Payment::Ledger"
  many_to_one :originating_payment_account, class: "Suma::Payment::Account"
  many_to_one :originated_book_transaction, class: "Suma::Payment::BookTransaction"
  one_to_many :audit_logs, class: "Suma::Payment::PayoutTransaction::AuditLog", order: Sequel.desc(:at)

  many_to_one :fake_strategy, class: "Suma::Payment::FakeStrategy"
  many_to_one :stripe_charge_refund_strategy, class: "Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy"

  many_to_many :associated_charges,
               class: "Suma::Charge",
               join_table: :charges_associated_payout_transactions,
               right_key: :charge_id,
               left_key: :payout_transaction_id

  state_machine :status, initial: :created do
    state :created,
          :sending,
          :settled,
          :needs_review,
          :canceled

    event :send_funds do
      transition created: :sending
      transition sending: :settled, if: :funds_settled?
    end

    event :cancel do
      transition [:created, :needs_review] => :canceled
    end
    event :put_into_review do
      transition (any - :needs_review) => :needs_review
    end

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  timestamp_accessors(
    [
      [{to: "sending"}, :funds_sending_at],
      [{to: "settled"}, :funds_settled_at],
      [{to: "needs_review"}, :put_into_review_at],
      [{to: "canceled"}, :canceled_at],
    ],
  )

  class << self
    # Force a fake strategy within a block. Mostly used for API tests,
    # since you can otherwise pass strategy explicitly to start_new.
    def force_fake(strat)
      raise LocalJumpError unless block_given?
      raise ArgumentError, "strat cannot be nil" if strat.nil?
      @fake_strategy = strat
      begin
        return yield
      ensure
        @fake_strategy = nil
      end
    end

    # Create a new payout transaction with the given parameters.
    # @param payment_account [Suma::Payment::Account] For the member/vendor/etc who is associated with this payout.
    # @param amount [Money] Amount of the payout.
    # @param strategy [Suma::Payment::PayoutTransaction::Strategy] Strategy to use for the payout.
    #   This must be passed in, since some payouts (like refunds) cannot be inferred by an instrument.
    #   When we need to find the strategy based on an instrument instead, we can add a method to do the inference
    #   (like exists in `FundingStrategy::start_new`).
    # @return [Suma::Payment::PayoutTransaction]
    def start_new(payment_account, amount:, strategy:)
      self.db.transaction do
        platform_ledger = Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
        strategy.check_validity!
        xaction = self.new(
          amount:,
          memo: Suma::TranslatedText.create(
            en: "Transfer from suma",
            es: "Transferencia de suma",
          ),
          originating_payment_account: payment_account,
          platform_ledger:,
          originated_book_transaction: nil,
          strategy:,
        )
        xaction.save_changes
        xaction.process(:send_funds) if xaction.strategy.ready_to_send_funds?
        return xaction
      end
    end

    # Like +start_new+, but also creates a +BookTransaction+ that moves funds
    # from the platform ledger into the receiving ledger.
    def start_and_transfer(payment_account, amount:, apply_at:, strategy:)
      self.db.transaction do
        originating_ledger = Suma::Payment.ensure_cash_ledger(payment_account)
        fx = Suma::Payment::PayoutTransaction.start_new(originating_ledger.account, amount:, strategy:)
        originated_book_transaction = Suma::Payment::BookTransaction.create(
          apply_at:,
          amount: fx.amount,
          originating_ledger:,
          receiving_ledger: fx.platform_ledger,
          associated_vendor_service_category: Suma::Vendor::ServiceCategory.cash,
          memo: fx.memo,
        )
        fx.update(originated_book_transaction:)
        fx
      end
    end
  end

  def rel_admin_link = "/payout-transaction/#{self.id}"

  protected def strategy_array
    return [
      self.stripe_charge_refund_strategy,
      self.fake_strategy,
    ]
  end

  #
  # :section: State Machine methods
  #

  def send_funds
    begin
      return false unless self.strategy.ready_to_send_funds?
      sent = self.strategy.send_funds
    rescue SendFundsFailed => e
      self.logger.error("send_funds_error", error: e)
      return self.put_into_review("Error sending funds", exception: e)
    end
    if sent
      self.originating_payment_account.member&.add_activity(
        message_name: "fundssending",
        subject_type: self.class.name,
        subject_id: self.id,
        summary: "PayoutTransaction[#{self.id}] started sending funds",
      )
    end
    return super
  end

  def funds_settled?
    return self.strategy.funds_settled?
  end

  def put_into_review(message, opts={})
    self._put_into_review_helper(message, opts)
    return super
  end
end
