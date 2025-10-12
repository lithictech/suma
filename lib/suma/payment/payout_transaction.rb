# frozen_string_literal: true

require "state_machines"

require "suma/admin_linked"
require "suma/state_machine"
require "suma/has_activity_audit"
require "suma/payment"
require "suma/payment/external_transaction"

class Suma::Payment::PayoutTransaction < Suma::Postgres::Model(:payment_payout_transactions)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  include Suma::HasActivityAudit
  include Suma::Payment::ExternalTransaction

  class InvalidAmount < Suma::InvalidPrecondition; end
  class SendFundsFailed < Suma::StateMachine::FailedTransition; end

  plugin :hybrid_search
  plugin :state_machine
  plugin :timestamps
  plugin :money_fields, :amount
  plugin :translated_text, :memo, Suma::TranslatedText

  many_to_one :platform_ledger, class: "Suma::Payment::Ledger"
  many_to_one :originating_payment_account, class: "Suma::Payment::Account"
  # Represents the book transaction from the user's ledger to the platform ledger,
  # to represent that money is leaving their ledger and eventually the system.
  many_to_one :originated_book_transaction, class: "Suma::Payment::BookTransaction"
  # If the payout fails, this reverses the originated_book_transaction.
  # Since money didn't leave the system, it should go back to the user's ledger.
  many_to_one :reversal_book_transaction, class: "Suma::Payment::BookTransaction"
  # Represent the book transaction from the platform ledger to the user's ledger
  # to compensate them for a refund.
  many_to_one :crediting_book_transaction, class: "Suma::Payment::BookTransaction"
  # The funding transaction that acts as a refund, if any.
  many_to_one :refunded_funding_transaction, class: "Suma::Payment::FundingTransaction"
  one_to_many :audit_logs, class: "Suma::Payment::PayoutTransaction::AuditLog", order: order_desc(:at)

  many_to_one :fake_strategy, class: "Suma::Payment::FakeStrategy"
  many_to_one :stripe_charge_refund_strategy, class: "Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy"
  many_to_one :off_platform_strategy, class: "Suma::Payment::OffPlatformStrategy"

  state_machine :status, initial: :created do
    state :created,
          :sending,
          :settled,
          :needs_review,
          :failed

    event :send_funds do
      transition created: :sending
      transition sending: :settled, if: :funds_settled?
      transition sending: :failed, if: :send_failed?
    end

    event :cancel do
      transition [:created, :needs_review] => :failed
    end

    event :put_into_review do
      transition (any - :needs_review) => :needs_review
    end

    after_transition to: :sending, do: :after_sending
    after_transition to: :failed, do: :after_failed

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  timestamp_accessors(
    [
      [{to: "sending"}, :funds_sending_at],
      [{to: "settled"}, :funds_settled_at],
      [{to: "needs_review"}, :put_into_review_at],
      [{to: "failed"}, :failed_at],
    ],
  )

  class << self
    # Create a new payout transaction with the given parameters.
    # @param payment_account [Suma::Payment::Account] For the member/vendor/etc who is associated with this payout.
    # @param amount [Money] Amount of the payout.
    # @param strategy [Suma::Payment::PayoutTransaction::Strategy] Strategy to use for the payout.
    #   This must be passed in, since some payouts (like refunds) cannot be inferred by an instrument.
    #   When we need to find the strategy based on an instrument instead, we can add a method to do the inference
    #   (like exists in `FundingStrategy::start_new`).
    # @return [Suma::Payment::PayoutTransaction]
    def start_new(payment_account, amount:, strategy:, memo: nil)
      self.db.transaction do
        platform_ledger = Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)
        strategy.check_validity!
        memo ||= Suma::TranslatedText.create(
          en: "Transfer from suma",
          es: "Transferencia de suma",
        )
        xaction = self.new(
          amount:,
          memo:,
          originating_payment_account: payment_account,
          platform_ledger:,
          strategy:,
        )
        xaction.save_changes
        xaction.process(:send_funds) if xaction.strategy.ready_to_send_funds?
        return xaction
      end
    end

    # Create and return a payout based on an existing funding transaction.
    #
    # Refund payouts are actually a two-step process: apply a credit, then do the payout.
    # The funds flow goes from the platform to member ledger (apply a credit),
    # then back from member to platform ledger (pay the credit out).
    #
    # If the payout fails, only this second transaction (member->platform) is reversed;
    # the member ends up with a credit on their ledger. This credit can be paid out
    # using a normal PayoutTransaction at this point, like writing a check
    # and then creating an OffPlatformPayout.
    #
    # In these cases, the payout fields are:
    # - +crediting_book_transaction+: The platform->member 'credit' transaction.
    # - +originated_book_transaction+: The member->platform 'pay this money out' transaction.
    # - +reversal_book_transaction+: If the money cannot move,
    #   this platform->member transaction reverses +originated_book_transaction+.
    #
    # @param funding_transaction [Suma::Payment::FundingTransaction]
    # @param amount [Money]
    # @param apply_at [Time]
    # @param strategy [:infer,Suma::Payment::PayoutTransaction::Strategy] If the strateg is known,
    #   pass it in. Otherwise, use +:infer+ to choose the payout strategy based on the funding strategy.
    #   Usually the strategy is known when backfilling from an external system,
    #   but is +:infer+ when running working from the funding transaction
    #   (the refund being processed asynchronously later).
    #
    # @return [Suma::Payment::PayoutTransaction]
    def initiate_refund(funding_transaction, amount:, apply_at:, strategy:)
      if amount > funding_transaction.refundable_amount
        msg = "refund cannot be greater than unrefunded amount of #{funding_transaction.refundable_amount.format}"
        raise InvalidAmount, msg
      end

      self.db.transaction do
        associated_vendor_service_category = Suma::Vendor::ServiceCategory.cash
        refund_memo = Suma::TranslatedText.create(
          en: "Refund sent to #{funding_transaction.strategy.originating_instrument_label}",
          es: "Reembolso enviado a #{funding_transaction.strategy.originating_instrument_label}",
        )
        if strategy == :infer
          strategy = case funding_transaction.strategy
            when Suma::Payment::FundingTransaction::StripeCardStrategy
              Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy.create(
                stripe_charge_id: funding_transaction.strategy.charge_id,
              )
            when Suma::Payment::FakeStrategy
              funding_transaction.strategy
            else
              raise ArgumentError, "no refund strategy for funding strategy #{funding_transaction.strategy.inspect}"
          end
        end
        px = Suma.set_request_now(apply_at) do
          self.start_new(
            funding_transaction.originating_payment_account,
            amount:,
            strategy:,
            memo: refund_memo,
          )
        end
        member_ledger = Suma::Payment.ensure_cash_ledger(funding_transaction.originating_payment_account)
        crediting_book_transaction = Suma::Payment::BookTransaction.create(
          apply_at: px.originated_book_transaction.apply_at - 0.001, # Apply 1 ms before the money movement out
          amount: px.amount,
          originating_ledger: px.platform_ledger,
          receiving_ledger: member_ledger,
          associated_vendor_service_category:,
          memo: Suma::TranslatedText.create(
            en: "Credit from suma",
            es: "Crédito de suma",
          ),
        )
        px.update(
          refunded_funding_transaction: funding_transaction,
          crediting_book_transaction:,
        )
        px
      end
    end
  end

  def rel_admin_link = "/payout-transaction/#{self.id}"

  protected def strategy_array
    return [
      self.stripe_charge_refund_strategy,
      self.off_platform_strategy,
      self.fake_strategy,
    ]
  end

  # Classify how to refer to this payout.
  # - 'refund' has a credit and refunding transaction,
  #   and is generally a reversal of money that was used to pay for something and charged during a purchase.
  # - 'reversal' has no credit but does have a refunding transaction,
  #   and is generally a reversal of money added to the ledger, not used directly in a purchase.
  # - 'payout' is money we send to a payment account, like to a vendor's bank account.
  # - 'platformpayout' is money we send off-platform without any associated book transaction.
  # - 'unknown' is a fallback and should not be seen with a valid combination of fields.
  def classification
    refund = self.refunded_funding_transaction_id
    credit = self.crediting_book_transaction_id
    originated = self.originated_book_transaction_id
    return "refund" if refund && credit
    return "reversal" if refund && originated
    return "payout" if originated
    return "platformpayout" if !refund && !credit && !originated
    return "unknown"
  end

  #
  # :section: State Machine methods
  #

  def send_funds
    begin
      return false unless self.strategy.ready_to_send_funds?
      send_result = self.strategy.send_funds
      Suma.assert { send_result.nil? }
    rescue SendFundsFailed => e
      self.logger.error("send_funds_error", error: e)
      return self.put_into_review("Error sending funds", exception: e)
    end
    return super
  end

  # Create the transaction from platform->member immediately on create.
  # We do not want to do it only after sending funds; since a payout could be coupled with a credit
  # (see +initiate_refund+), we need to make we don't provide a credit, then the user could pay it down,
  # then we'd try to move money off-platform (originated book transaction).
  def after_create
    super
    self._originate_book_transaction(
      originating_ledger: Suma::Payment.ensure_cash_ledger(self.originating_payment_account),
      receiving_ledger: self.platform_ledger,
    )
  end

  def after_sending
    if (member = self.originating_payment_account.member)
      self.audit_activity(
        "fundssending",
        actor: member,
        summary: "PayoutTransaction[#{self.id}] started sending funds",
      )
    end
  end

  def after_failed
    if self.reversal_book_transaction.nil? && (orig_bx = self.originated_book_transaction)
      self.db.transaction do
        reversal_book_transaction = Suma::Payment::BookTransaction.create(
          apply_at: Suma.request_now,
          amount: orig_bx.amount,
          originating_ledger: orig_bx.receiving_ledger,
          receiving_ledger: orig_bx.originating_ledger,
          associated_vendor_service_category: orig_bx.associated_vendor_service_category,
          memo: self.memo,
        )
        self.update(reversal_book_transaction:)
      end
    end
  end

  def funds_settled? = self.strategy.funds_settled?
  def send_failed? = self.strategy.send_failed?

  def put_into_review(message, opts={})
    self._put_into_review_helper(message, opts)
    return super
  end

  def hybrid_search_fields
    return [
      :status,
      :amount,
      :classification,
      :memo,
    ]
  end
end

# Table: payment_payout_transactions
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                               | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                       | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                       | timestamp with time zone |
#  status                           | text                     | NOT NULL
#  amount_cents                     | integer                  | NOT NULL
#  amount_currency                  | text                     | NOT NULL
#  memo_id                          | integer                  | NOT NULL
#  platform_ledger_id               | integer                  | NOT NULL
#  refunded_funding_transaction_id  | integer                  |
#  originating_payment_account_id   | integer                  | NOT NULL
#  crediting_book_transaction_id    | integer                  |
#  originated_book_transaction_id   | integer                  |
#  fake_strategy_id                 | integer                  |
#  stripe_charge_refund_strategy_id | integer                  |
#  search_content                   | text                     |
#  search_embedding                 | vector(384)              |
#  search_hash                      | text                     |
# Indexes:
#  payment_payout_transactions_pkey                                | PRIMARY KEY btree (id)
#  payment_payout_transactions_crediting_book_transaction_id_key   | UNIQUE btree (crediting_book_transaction_id)
#  payment_payout_transactions_fake_strategy_id_key                | UNIQUE btree (fake_strategy_id)
#  payment_payout_transactions_originated_book_transaction_id_key  | UNIQUE btree (originated_book_transaction_id)
#  payment_payout_transactions_stripe_charge_refund_strategy_i_key | UNIQUE btree (stripe_charge_refund_strategy_id)
#  payment_payout_transactions_originating_payment_account_id_inde | btree (originating_payment_account_id)
#  payment_payout_transactions_platform_ledger_id_index            | btree (platform_ledger_id)
#  payment_payout_transactions_refunded_funding_transaction_id_ind | btree (refunded_funding_transaction_id)
#  payment_payout_transactions_search_content_tsvector_index       | gin (to_tsvector('english'::regconfig, search_content))
# Check constraints:
#  amount_positive      | (amount_cents > 0)
#  refund_fields_valid  | (refunded_funding_transaction_id IS NOT NULL AND crediting_book_transaction_id IS NOT NULL AND originated_book_transaction_id IS NOT NULL OR refunded_funding_transaction_id IS NULL AND crediting_book_transaction_id IS NULL AND originated_book_transaction_id IS NULL OR refunded_funding_transaction_id IS NULL AND crediting_book_transaction_id IS NULL AND originated_book_transaction_id IS NOT NULL OR refunded_funding_transaction_id IS NOT NULL AND crediting_book_transaction_id IS NULL AND originated_book_transaction_id IS NOT NULL)
#  unambiguous_strategy | (fake_strategy_id IS NOT NULL AND stripe_charge_refund_strategy_id IS NULL OR fake_strategy_id IS NULL AND stripe_charge_refund_strategy_id IS NOT NULL)
# Foreign key constraints:
#  payment_payout_transactions_crediting_book_transaction_id_fkey  | (crediting_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_payout_transactions_fake_strategy_id_fkey               | (fake_strategy_id) REFERENCES payment_fake_strategies(id)
#  payment_payout_transactions_memo_id_fkey                        | (memo_id) REFERENCES translated_texts(id)
#  payment_payout_transactions_originated_book_transaction_id_fkey | (originated_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  payment_payout_transactions_originating_payment_account_id_fkey | (originating_payment_account_id) REFERENCES payment_accounts(id) ON DELETE RESTRICT
#  payment_payout_transactions_platform_ledger_id_fkey             | (platform_ledger_id) REFERENCES payment_ledgers(id) ON DELETE RESTRICT
#  payment_payout_transactions_refunded_funding_transaction_i_fkey | (refunded_funding_transaction_id) REFERENCES payment_funding_transactions(id) ON DELETE RESTRICT
#  payment_payout_transactions_stripe_charge_refund_strategy__fkey | (stripe_charge_refund_strategy_id) REFERENCES payment_payout_transaction_stripe_charge_refund_strategies(id)
# Referenced By:
#  payment_payout_transaction_audit_logs | payment_payout_transaction_audit_log_payout_transaction_id_fkey | (payout_transaction_id) REFERENCES payment_payout_transactions(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
