# frozen_string_literal: true

require "suma/stripe"
require "suma/webhookdb"
require "suma/payment/payout_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy <
  Suma::Postgres::Model(:payment_payout_transaction_stripe_charge_refund_strategies)
  include Suma::Payment::PayoutTransaction::Strategy

  # Don't use a NotImplementedError since that's used for abstract methods.
  class WorkInProgressImplementation < StandardError; end

  one_to_one :payout_transaction, class: "Suma::Payment::PayoutTransaction"

  def short_name = "Stripe Card Payout"

  def admin_details
    return {
      "Stripe Refund" => self.refund_json,
    }
  end

  def check_validity
    return []
  end

  def ready_to_send_funds? = true

  def refund_id = self.refund_json&.fetch("id")

  def send_funds
    if self.refund_id.present?
      return if self.refund_json["status"] == "succeeded"
      raise WorkInProgressImplementation, "handling not-succeeded refunds is not implemented"
    end
    refund = Stripe::Refund.create(
      {
        charge: self.stripe_charge_id,
        amount: self.payout_transaction.amount.cents,
        metadata: Suma::Stripe.build_metadata(
          [
            self.payout_transaction.originating_payment_account.member,
            self.payout_transaction,
          ],
        ),
      },
      idempotency_key: Suma.idempotency_key(self.payout_transaction, "refund"),
    )
    self.refund_json = refund.as_json
    refund_id_set!
    return
  end

  def funds_settled?
    refund_id_set!
    return self.refund_json["status"] == "succeeded"
  end

  UNFAILED_STATES = ["pending", "succeeded"].freeze

  def send_failed?
    refund_id_set!
    return !UNFAILED_STATES.include?(self.refund_json["status"])
  end

  private def refund_id_set!
    return if self.refund_id.present?
    msg = "Stripe id not set after API call from #{self.class.name}[#{self.id}]. " \
          "JSON: #{self.refund_json}"
    raise Suma::InvalidPostcondition, msg
  end

  def _external_links_self
    arr = [
      self._external_link(
        "Stripe Charge",
        "#{Suma::Stripe.app_url}/payments/#{self.stripe_charge_id}",
      ),
    ]
    return arr
  end

  # Create PayoutTransactions for Stripe refunds in WebhookDB.
  # - Only process Stripe refunds where the charge has a FundingTransaction in suma.
  # - If the funding transaction was used in an order (ie charged at checkout),
  #   credit the user the refund amount, then show it as sent back to their card.
  # - If the funding transaction wasn't used in an order (ie loaded from dashboard)
  #   do not create the credit.
  # This should cover cases where users do things like:
  # - Add too many funds from their dashboard (no credit, just refund)
  # - Checkout without the right subsidy (partial credit and refund)
  # - Checkout but never get their stuff (full credit and refund)
  def self.backfill_payouts_from_webhookdb
    last_ran_at = self.dataset.max(:created_at) || Time.at(0)
    # Apply some buffer, we never want to miss a refund, and processing the same row
    # multiple times is fine.
    last_ran_at -= 10.minutes
    refunds_ds = Suma::Webhookdb.stripe_refunds_dataset.
      where { created > last_ran_at }.
      where(status: "succeeded")
    refunds_ds.each do |refund_row|
      refund_json = refund_row.fetch(:data)
      stripe_charge_id = refund_row.fetch(:charge)
      self.db.transaction do
        # Find a funding strategy first, so if we don't want to process this row
        # we don't end up creating anything.
        funding_strategy = Suma::Payment::FundingTransaction::StripeCardStrategy.
          where(Sequel.pg_jsonb_op(:charge_json).get_text("id") => stripe_charge_id).
          first
        # We only want to process Stripe refunds that are attached to charges initiated by our backend.
        # We don't want to pick up random charges/refunds.
        next unless funding_strategy

        strat = self[Sequel.pg_jsonb_op(:refund_json).get_text("id") => refund_row.fetch(:stripe_id)]
        strat ||= self.create(refund_json:, stripe_charge_id:)
        existing_payout = Suma::Payment::PayoutTransaction[stripe_charge_refund_strategy: strat]
        next if existing_payout

        px = Suma::Payment::PayoutTransaction.initiate_refund(
          funding_strategy.funding_transaction,
          amount: Money.new(refund_row.fetch(:amount)),
          apply_at: refund_row.fetch(:created),
          strategy: strat,
        )
        # We only process succeeded refunds, so this transition should/must always succeed.
        px.must_process(:send_funds)
      end
    end
  end
end

# Table: payment_payout_transaction_stripe_charge_refund_strategies
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id               | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at       | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at       | timestamp with time zone |
#  stripe_charge_id | text                     | NOT NULL
#  refund_json      | jsonb                    |
# Indexes:
#  payment_payout_transaction_stripe_charge_refund_strategies_pkey | PRIMARY KEY btree (id)
# Referenced By:
#  payment_payout_transactions | payment_payout_transactions_stripe_charge_refund_strategy__fkey | (stripe_charge_refund_strategy_id) REFERENCES payment_payout_transaction_stripe_charge_refund_strategies(id)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
