# frozen_string_literal: true

require "state_machines"
require "suma/payment"
require "suma/state_machine"

class Suma::Payment::FundingTransaction < Suma::Postgres::Model(:payment_funding_transactions)
  include Appydays::Configurable

  class CollectFundsFailed < Suma::StateMachine::FailedTransition; end
  class StrategyUnavailable < Suma::Payment::Error; end

  plugin :state_machine
  plugin :timestamps
  plugin :money_fields, :amount

  many_to_one :platform_ledger, class: "Suma::Payment::Ledger"
  many_to_one :originating_payment_account, class: "Suma::Payment::Account"
  many_to_one :originated_book_transaction, class: "Suma::Payment::BookTransaction"
  one_to_many :audit_logs, class: "Suma::Payment::FundingTransaction::AuditLog", order: Sequel.desc(:at)

  many_to_one :fake_strategy, class: "Suma::Payment::FakeStrategy"
  many_to_one :increase_ach_strategy, class: "Suma::Payment::FundingTransaction::IncreaseAchStrategy"

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

  # Create a new funding transaction with the given parameters.
  # @param [Suma::Payment::Account] payment_account
  # @param [Money] amount
  # @param [Suma::BankAccount] bank_account If given, use an ACH strategy sending from this account.
  # @param [Suma::Payment::FundingTransaction::Strategy] strategy Explicit override to use this strategy.
  #   When using a FakeStrategy, pass it in this way.
  # @return [Suma::Payment::FundingTransaction]
  def self.start_new(payment_account, amount:, bank_account: nil, strategy: nil)
    self.db.transaction do
      platform_ledger = Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
      strategy ||= if bank_account
                     IncreaseAchStrategy.create(originating_bank_account: bank_account)
      else
        raise StrategyUnavailable, "cannot determine valid funding strategy for given arguments"
      end
      strategy.check_validity!
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
    raise "Strategy type #{strat.class.name} does not match any association type on FundingTransaction"
  end

  protected def strategy_array
    return [
      self.increase_ach_strategy,
      self.fake_strategy,
    ]
  end

  #
  # :section: State Machine methods
  #

  def collect_funds
    begin
      return false unless self.strategy.ready_to_collect_funds?
      collected = self.strategy.collect_funds
    rescue CollectFundsFailed => e
      self.logger.error("collect_funds_error", error: e)
      return self.put_into_review("Error collecting funds", exception: e)
    end
    if collected
      self.originating_payment_account.member&.add_activity(
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
    errors.add(:strategy, "is not available using strategy associations") unless self.strategy_array.any?
  end
end

# Table: payment_funding_transactions
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                             | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                     | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                     | timestamp with time zone |
#  status                         | text                     | NOT NULL
#  amount_cents                   | integer                  | NOT NULL
#  amount_currency                | text                     | NOT NULL
#  memo                           | text                     | NOT NULL
#  originating_payment_account_id | integer                  | NOT NULL
#  platform_ledger_id             | integer                  | NOT NULL
#  originated_book_transaction_id | integer                  |
#  fake_strategy_id               | integer                  |
#  increase_ach_strategy_id       | integer                  |
# Indexes:
#  payment_funding_transactions_pkey                               | PRIMARY KEY btree (id)
#  payment_funding_transactions_fake_strategy_id_key               | UNIQUE btree (fake_strategy_id)
#  payment_funding_transactions_increase_ach_strategy_id_key       | UNIQUE btree (increase_ach_strategy_id)
#  payment_funding_transactions_originated_book_transaction_id_key | UNIQUE btree (originated_book_transaction_id)
#  payment_funding_transactions_originating_payment_account_id_ind | btree (originating_payment_account_id)
#  payment_funding_transactions_platform_ledger_id_index           | btree (platform_ledger_id)
# Check constraints:
#  amount_positive      | (amount_cents > 0)
#  unambiguous_strategy | (fake_strategy_id IS NOT NULL AND increase_ach_strategy_id IS NULL OR fake_strategy_id IS NULL AND increase_ach_strategy_id IS NOT NULL)
# Foreign key constraints:
#  payment_funding_transactions_fake_strategy_id_fkey              | (fake_strategy_id) REFERENCES payment_fake_strategies(id)
#  payment_funding_transactions_increase_ach_strategy_id_fkey      | (increase_ach_strategy_id) REFERENCES payment_funding_transaction_increase_ach_strategies(id)
#  payment_funding_transactions_originated_book_transaction_i_fkey | (originated_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_funding_transactions_originating_payment_account_i_fkey | (originating_payment_account_id) REFERENCES payment_accounts(id) ON DELETE RESTRICT
#  payment_funding_transactions_platform_ledger_id_fkey            | (platform_ledger_id) REFERENCES payment_ledgers(id) ON DELETE RESTRICT
# Referenced By:
#  payment_funding_transaction_audit_logs | payment_funding_transaction_audit_l_funding_transaction_id_fkey | (funding_transaction_id) REFERENCES payment_funding_transactions(id)
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
