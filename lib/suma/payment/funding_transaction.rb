# frozen_string_literal: true

require "state_machines"
require "suma/payment"
require "suma/state_machine"

class Suma::Payment::FundingTransaction < Suma::Postgres::Model(:payment_funding_transactions)
  include Appydays::Configurable

  class CollectFundsFailed < Suma::StateMachine::FailedTransition; end

  plugin :state_machine
  plugin :timestamps
  plugin :money_fields, :amount

  many_to_one :platform_ledger, class: "Suma::Payment::Ledger"
  many_to_one :originating_payment_account, class: "Suma::Payment::Account"
  many_to_one :originated_book_transaction, class: "Suma::Payment::BookTransaction"
  one_to_many :audit_logs, class: "Suma::Payment::FundingTransaction::AuditLog", order: Sequel.desc(:at)

  many_to_one :fake_strategy, class: "Suma::Payment::FakeStrategy"

  state_machine :status, initial: :created do
    state :created,
          :collecting,
          :cleared,
          :needs_review,
          :canceled

    event :collect_funds do
      transition created: :collecting
      transition collecting: :cleared, if: :funds_cleared?
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
      [{to: "collecting"}, :funds_collecting_at],
      [{to: "cleared"}, :funds_cleared_at],
      [{to: "needs_review"}, :put_into_review_at],
      [{to: "canceled"}, :canceled_at],
    ],
  )

  def self.start_new(payment_account, amount:, fake_strategy: false)
    self.db.transaction do
      platform_ledger = Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
      strategy = fake_strategy ? Suma::Payment::FakeStrategy.create : (raise NotImplementedError)
      xaction = self.new(
        amount:,
        memo: "Transfer to Suma App",
        originating_payment_account: payment_account,
        platform_ledger:,
        originated_book_transaction: nil,
        strategy:,
      )
      xaction.save_changes
      return xaction
    end
  end

  # @return [Suma::Payment::FundingTransaction::Strategy]
  def strategy
    strat = self.strategy_array.compact.first
    return strat if strat
    return nil if self.new?
    raise "FundingTransaction[#{self.id}] has no strategy set, should not have been possible due to constraints"
  end

  # @param [Suma::Payment::FundingTransaction::Strategy] strat
  def strategy=(strat)
    # We cannot just do strat.payment = self, it triggers a save and we're not valid yet/don't want that
    self.class.association_reflections.each_value do |details|
      type_match = details[:class_name] == strat.class.name
      next unless type_match
      self.associations[details[:name]] = strat
      self["#{details[:name]}_id"] = strat.id
      strat.associations[:payment] = self
      return strat
    end
    raise "Strategy type #{strat.class.name} does not match any association type on Payment"
  end

  protected def strategy_array
    return [
      self.fake_strategy,
    ]
  end

  #
  # :section: State Machine methods
  #

  def collect_funds
    return false unless self.strategy.ready_to_collect_funds?
    begin
      collected = self.strategy.collect_funds
    rescue CollectFundsFailed => e
      self.logger.error("collect_funds_error", error: e)
      return self.put_into_review("Error collecting funds", exception: e)
    end
    if collected
      self.originating_payment_account.customer&.add_activity(
        message_name: "fundscollecting",
        subject_type: self.class.name,
        subject_id: self.id,
        summary: "FundingTransaction[#{self.id}] started collecting funds",
      )
    end
    return super
  end

  def funds_cleared?
    return self.strategy.funds_cleared?
  end

  def put_into_review(message, opts={})
    reason = nil
    if opts[:reason]
      reason = opts[:reason]
    elsif (ex = opts[:exception])
      reason = ex.class.name
      message = "#{message}: #{ex}"
      reason = ex.wrapped.class.name if ex.respond_to?(:wrapped)
    end
    self.audit(message, reason:)
    return super
  end

  #
  # :section: Sequel Hooks
  #

  def after_save
    super
    # Save the strategy changes whenever we save the payment, otherwise it's very easy to forget.
    self.strategy&.save_changes
  end

  def validate(*)
    super
    self.strategy_present
  end

  private def strategy_present
    errors.add(:base, "Specify a strategy") unless self.strategy_array.any?
  end
end
