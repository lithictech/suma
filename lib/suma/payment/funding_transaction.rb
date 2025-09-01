# frozen_string_literal: true

require "state_machines"

require "suma/admin_linked"
require "suma/state_machine"
require "suma/has_activity_audit"
require "suma/payment"
require "suma/payment/external_transaction"

class Suma::Payment::FundingTransaction < Suma::Postgres::Model(:payment_funding_transactions)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  include Suma::HasActivityAudit
  include Suma::Payment::ExternalTransaction

  class CollectFundsFailed < Suma::StateMachine::FailedTransition; end
  class StrategyUnavailable < Suma::Payment::Error; end

  plugin :hybrid_search
  plugin :state_machine
  plugin :timestamps
  plugin :money_fields, :amount
  plugin :translated_text, :memo, Suma::TranslatedText

  many_to_one :platform_ledger, class: "Suma::Payment::Ledger"
  many_to_one :originating_payment_account, class: "Suma::Payment::Account"
  many_to_one :originated_book_transaction, class: "Suma::Payment::BookTransaction"
  one_to_many :audit_logs, class: "Suma::Payment::FundingTransaction::AuditLog", order: order_desc(:at)

  many_to_one :fake_strategy, class: "Suma::Payment::FakeStrategy"
  many_to_one :increase_ach_strategy, class: "Suma::Payment::FundingTransaction::IncreaseAchStrategy"
  many_to_one :stripe_card_strategy, class: "Suma::Payment::FundingTransaction::StripeCardStrategy"
  many_to_one :off_platform_strategy, class: "Suma::Payment::OffPlatformStrategy"

  many_to_many :associated_charges,
               class: "Suma::Charge",
               join_table: :charges_associated_funding_transactions,
               right_key: :charge_id,
               left_key: :funding_transaction_id,
               order: order_desc

  one_to_many :refund_payout_transactions,
              class: "Suma::Payment::PayoutTransaction",
              key: :refunded_funding_transaction_id,
              order: order_desc

  state_machine :status, initial: :created do
    state :created,
          :collecting,
          :cleared,
          :needs_review,
          :canceled

    event :collect_funds do
      transition created: :collecting
      transition collecting: :cleared, if: :funds_cleared?
      transition collecting: :canceled, if: :funds_canceled?
      transition collecting: :needs_review, if: :flagging_for_review?
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

  class << self
    # Create a new funding transaction with the given parameters.
    # @param [Suma::Payment::Account] payment_account
    # @param [Money] amount
    # @param [Suma::Payment::Instrument::Interface] instrument The payment instrument to use.
    #   Use an ACH strategy for bank accounts, Card strategy for cards, etc.
    # @param [String] originating_ip The IP of the user starting this transaction.
    #   Only some strategies, like cards, require this to be set.
    # @param [Suma::Payment::FundingTransaction::Strategy] strategy Explicit override to use this strategy.
    #   When using a FakeStrategy, pass it in this way.
    # @return [Suma::Payment::FundingTransaction]
    def start_new(payment_account, amount:, instrument: nil, originating_ip: nil, strategy: nil, collect: true)
      if strategy.nil?
        strategy = @fake_strategy.respond_to?(:call) ? @fake_strategy.call : @fake_strategy
      end
      self.db.transaction do
        platform_ledger = Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
        if strategy.nil?
          raise ArgumentError, ":instrument must be provided if :strategy is not" if instrument.nil?
          pmt = instrument.payment_method_type
          raise Suma::Payment::UnsupportedMethod, "#{pmt} is not supported" unless Suma::Payment.method_supported?(pmt)
          strategy = case pmt
            when "bank_account"
              IncreaseAchStrategy.create(originating_bank_account: instrument)
            when "card"
              StripeCardStrategy.create(originating_card: instrument)
            else
              raise StrategyUnavailable, "cannot determine valid funding strategy for given arguments"
          end
        end
        strategy.check_validity!
        xaction = self.new(
          amount:,
          memo: Suma::TranslatedText.create(
            en: "Transfer to suma",
            es: "Transferencia a suma",
          ),
          originating_payment_account: payment_account,
          platform_ledger:,
          originating_ip:,
          originated_book_transaction: nil,
          strategy:,
        )
        xaction.save_changes
        xaction.process(:collect_funds) if collect && xaction.strategy.ready_to_collect_funds?
        return xaction
      end
    end

    # Like +start_new+, but also creates a +BookTransaction+ that moves funds
    # from the platform cash ledger into the cash ledger on payment_account.
    def start_and_transfer(member_or_payment_account, amount:, apply_at:, instrument: nil, strategy: nil)
      receiving_ledger = Suma::Payment.ensure_cash_ledger(member_or_payment_account)
      vendor_service_category = Suma::Vendor::ServiceCategory.cash
      self.db.transaction do
        # collect should always be true, since making the funds available implies we try to collect them.
        fx = self.start_new(receiving_ledger.account, amount:, instrument:, strategy:, collect: true)
        originated_book_transaction = Suma::Payment::BookTransaction.create(
          apply_at:,
          amount: fx.amount,
          originating_ledger: fx.platform_ledger,
          receiving_ledger:,
          associated_vendor_service_category: vendor_service_category,
          memo: fx.memo,
        )
        fx.update(originated_book_transaction:)
        fx
      end
    end
  end

  def refunded_amount = self.refund_payout_transactions.sum(Money.new(0), &:amount)
  def refundable_amount = self.amount - self.refunded_amount
  def can_refund? = self.refundable_amount.positive? && self.strategy.supports_refunds?

  def rel_admin_link = "/funding-transaction/#{self.id}"

  protected def strategy_array
    return [
      self.stripe_card_strategy,
      self.off_platform_strategy,
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
    if collected && (member = self.originating_payment_account.member)
      self.audit_activity(
        "fundscollecting",
        actor: member,
        summary: "FundingTransaction[#{self.id}] started collecting funds",
      )
    end
    return super
  end

  def funds_cleared? = self.strategy.funds_cleared?
  def funds_canceled? = self.strategy.funds_canceled?

  # Generic helper for when a strategy asks a transaction to move into +needs_review+,
  # rather than the strategy calling a separate transition method on the transaction.
  def flagging_for_review? = self.strategy.flagging_for_review?

  def put_into_review(message, opts={})
    self._put_into_review_helper(message, opts)
    return super
  end

  def hybrid_search_fields
    return [
      :status,
      :amount,
      :memo,
    ]
  end
end

# Table: payment_funding_transactions
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                             | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                     | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                     | timestamp with time zone |
#  status                         | text                     | NOT NULL
#  amount_cents                   | integer                  | NOT NULL
#  amount_currency                | text                     | NOT NULL
#  originating_payment_account_id | integer                  | NOT NULL
#  platform_ledger_id             | integer                  | NOT NULL
#  originated_book_transaction_id | integer                  |
#  fake_strategy_id               | integer                  |
#  increase_ach_strategy_id       | integer                  |
#  originating_ip                 | inet                     |
#  stripe_card_strategy_id        | integer                  |
#  memo_id                        | integer                  | NOT NULL
#  search_content                 | text                     |
#  search_embedding               | vector(384)              |
#  search_hash                    | text                     |
# Indexes:
#  payment_funding_transactions_pkey                               | PRIMARY KEY btree (id)
#  payment_funding_transactions_fake_strategy_id_key               | UNIQUE btree (fake_strategy_id)
#  payment_funding_transactions_increase_ach_strategy_id_key       | UNIQUE btree (increase_ach_strategy_id)
#  payment_funding_transactions_originated_book_transaction_id_key | UNIQUE btree (originated_book_transaction_id)
#  payment_funding_transactions_stripe_card_strategy_id_key        | UNIQUE btree (stripe_card_strategy_id)
#  payment_funding_transactions_originating_payment_account_id_ind | btree (originating_payment_account_id)
#  payment_funding_transactions_platform_ledger_id_index           | btree (platform_ledger_id)
#  payment_funding_transactions_search_content_tsvector_index      | gin (to_tsvector('english'::regconfig, search_content))
# Check constraints:
#  amount_positive      | (amount_cents > 0)
#  unambiguous_strategy | (fake_strategy_id IS NOT NULL AND increase_ach_strategy_id IS NULL AND stripe_card_strategy_id IS NULL OR fake_strategy_id IS NULL AND increase_ach_strategy_id IS NOT NULL AND stripe_card_strategy_id IS NULL OR fake_strategy_id IS NULL AND increase_ach_strategy_id IS NULL AND stripe_card_strategy_id IS NOT NULL)
# Foreign key constraints:
#  payment_funding_transactions_fake_strategy_id_fkey              | (fake_strategy_id) REFERENCES payment_fake_strategies(id)
#  payment_funding_transactions_increase_ach_strategy_id_fkey      | (increase_ach_strategy_id) REFERENCES payment_funding_transaction_increase_ach_strategies(id)
#  payment_funding_transactions_memo_id_fkey                       | (memo_id) REFERENCES translated_texts(id)
#  payment_funding_transactions_originated_book_transaction_i_fkey | (originated_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_funding_transactions_originating_payment_account_i_fkey | (originating_payment_account_id) REFERENCES payment_accounts(id) ON DELETE RESTRICT
#  payment_funding_transactions_platform_ledger_id_fkey            | (platform_ledger_id) REFERENCES payment_ledgers(id) ON DELETE RESTRICT
#  payment_funding_transactions_stripe_card_strategy_id_fkey       | (stripe_card_strategy_id) REFERENCES payment_funding_transaction_stripe_card_strategies(id)
# Referenced By:
#  charges_associated_funding_transactions | charges_associated_funding_transact_funding_transaction_id_fkey | (funding_transaction_id) REFERENCES payment_funding_transactions(id)
#  payment_funding_transaction_audit_logs  | payment_funding_transaction_audit_l_funding_transaction_id_fkey | (funding_transaction_id) REFERENCES payment_funding_transactions(id)
#  payment_payout_transactions             | payment_payout_transactions_refunded_funding_transaction_i_fkey | (refunded_funding_transaction_id) REFERENCES payment_funding_transactions(id) ON DELETE RESTRICT
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
