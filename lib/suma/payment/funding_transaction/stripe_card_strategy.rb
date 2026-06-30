# frozen_string_literal: true

require "suma/stripe"
require "suma/payment/funding_transaction/strategy"
require "suma/postgres/model"

# Stripe card funding transactions have some subtleties because of async refunds/failures/disputes.
# - An uncaptured charge is created on collect_funds.
#   Collecting funds causes the funding transaction to originate the book transaction.
# - The charge is captured on funds_cleared? The funds are cleared if captured.
# - If the charge has failed (no money moved), then funds_canceled? is true.
#   This will cause the funding transaction to create a reversal.
# - If the charge is refunded, then the 'reversal' book transaction is handled as part of the payout.
class Suma::Payment::FundingTransaction::StripeCardStrategy <
  Suma::Postgres::Model(:payment_funding_transaction_stripe_card_strategies)
  include Suma::Payment::FundingTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"
  many_to_one :originating_card, class: "Suma::Payment::Card"

  def originating_instrument_label = self.originating_card.simple_label
  def short_name = "Stripe Card Funding"
  def supports_refunds? = true

  def admin_details
    return {
      "Suma Card" => self.originating_card,
      "Stripe Charge" => self.charge_json,
    }
  end

  def check_validity
    card = self.originating_card
    result = []
    (result << "is soft deleted and cannot be used for funding") if card.soft_deleted?
    raise Suma::InvalidPrecondition, "card is not owned by a member, should only see this in tests" if card.member.nil?
    (result << "member is not registered in Stripe") unless card.member.stripe.registered_as_customer?
    return result
  end

  def ready_to_collect_funds?
    return true
  end

  def charge_id = self.charge_json&.fetch("id")

  def collect_funds
    return if self.charge_id.present?
    begin
      charge = self.originating_card.member.stripe.charge_card(
        card: self.originating_card,
        amount: self.funding_transaction.amount,
        memo: "#{Suma.operator_name} charge",
        idempotency_key: Suma.idempotency_key(self, "charge"),
        params: {capture: true},
        metadata: {suma_funding_transaction_id: self.funding_transaction.id},
      )
    rescue Stripe::CardError => e
      raise Suma::Payment::FundingTransaction::CollectFundsFailed.new(
        message: e.message,
        type: "card_error",
        code: e.code,
        sub_code: e.json_body&.dig(:error, :decline_code),
        localized_error_code: Suma::Stripe.localized_error_code(e),
      )
    end
    self.charge_json = charge.as_json
    charge_id_set!(Suma::InvalidPostcondition)
  end

  def funds_cleared?
    charge_id_set!(Suma::InvalidPrecondition)
    return true if self.charge_json["captured"]
    begin
      charge = Stripe::Charge.capture(self.charge_id)
    rescue Stripe::InvalidRequestError => e
      case e.code
        when "charge_already_captured"
        # This is fine; just re-fetch it.
        when "charge_already_refunded"
        # It's possible for the charge to be refunded before it is captured,
        # in which case, we can pull a fresh version of the charge and see it's refunded,
        # and the funding transaction will be canceled.
        when "charge_expired_for_capture"
          # This should never happen, but it could if the payment processor is offline
          # for a long time. We always want to know about these,
          # but we'll probably just move them to 'canceled' manually.
          self.flag_for_review
          return false
      else
          raise e
      end
      charge = Stripe::Charge.retrieve(self.charge_id)
    end
    self.charge_json = charge.as_json
    charge_id_set!(Suma::InvalidPostcondition)
    return self.charge_json["captured"]
  end

  def funds_canceled?
    charge_id_set!(Suma::InvalidPrecondition)
    return self.charge_json["status"] == "failed"
  end

  private def charge_id_set!(cls)
    return if self.charge_id.present?
    msg = "Stripe charge id not set after API call from #{self.class.name}[#{self.id}]. " \
          "JSON: #{self.charge_json}"
    raise cls, msg
  end

  def _external_links_self
    return [] unless self.charge_id
    return [
      self._external_link(
        "Stripe Charge",
        "#{Suma::Stripe.app_url}/payments/#{self.charge_id}",
      ),
    ]
  end

  def _external_link_deps
    return [self.originating_card]
  end

  class UnassociatedChargeRefunder
    attr_reader :row_iterator

    def initialize(newer_than: 2.weeks, older_than: 2.hours)
      @newer_than = newer_than # Do not look back indefinitely
      @older_than = older_than # In theory this could be 30 seconds
      @row_iterator = Suma::Webhookdb::RowIterator.new("stripe/unassociatedchargerefunder/pk")
    end

    # Yield each row in the dataset that we need to process.
    # Since the webhookdb table is in a separate DB from the funding transactions,
    # we cannot do this with a simple query in the dataset.
    # So we pull all the rows,
    # so we need to run this check here.
    def each
      ds = self.dataset
      @row_iterator.each_page(ds) do |page|
        fx_ids_from_stripe = page.to_set do |r|
          r.fetch(:data).fetch("metadata").fetch("suma_funding_transaction_id").to_i
        end
        fx_ids_in_suma = Suma::Payment::FundingTransaction.where(id: fx_ids_from_stripe).select_map(:id)
        page.each do |row|
          fx_id = row.fetch(:data).fetch("metadata").fetch("suma_funding_transaction_id").to_i
          yield(row) unless fx_ids_in_suma.include?(fx_id)
        end
      end
    end

    def run
      self.each do |row|
        stripe_charge_id = row.fetch(:stripe_id)
        Suma::Idempotency.once_ever.under_key("refund-unassociated-stripe-charge-#{stripe_charge_id}") do
          member_name = row.fetch(:data).fetch("source").fetch("name", "")
          member_id = row.fetch(:data).fetch("source").fetch("metadata", {})["suma_member_id"] || "<unknown>"
          body_lines = [
            "Suma charged a member, but an error in the backend caused the charge to be lost.",
            "We have refunded the charge, and it will take about 5 business days to appear.",
            "No action is necessary, but please let the member know if they contact support.",
            "See this charge in Stripe: #{Suma::Stripe.app_url}/payments/#{stripe_charge_id}",
            "Member Name: #{member_name}",
            "Suma Member Id: #{member_id}",
          ]
          Suma::Support::Ticket.create(
            subject: "Refunding Unassociated Stripe Charge",
            body: body_lines.join("\n"),
            external_id: "refund-#{stripe_charge_id}",
          )
          Stripe::Refund.create(charge: row.fetch(:stripe_id))
        end
      end
    end

    def dataset
      data = Sequel.pg_jsonb(:data)
      newer_than = @newer_than.ago
      older_than = @older_than.ago
      # rubocop:disable Style/PreferredHashMethods
      ds = Suma::Webhookdb.stripe_charges_dataset.
        where(status: "succeeded").
        where { created > newer_than }.
        where { created < older_than }.
        where(
          data.get("metadata").has_key?("suma_funding_transaction_id") &
            Sequel[data.get_text("captured") => "true"] &
            Sequel[data.get_text("refunded") => "false"],
        )
      # rubocop:enable Style/PreferredHashMethods
      return ds
    end
  end

  # It is possible that we create captured Stripe charges,
  # but the transaction fails due to a database outage or other error,
  # and the suma side never commits.
  #
  # We can detect this has happened by looking for charges which:
  # - Are captured,
  # - Have the expected metadata ('suma_funding_transaction_id'),
  # - Do not have a corresponding strategy row.
  #
  # These charges can be refunded. We track where this happens with a support ticket,
  # both to make sure it isn't common,
  # and because a user may reach out about the charge in the meantime.
  def self.refund_unassociated_charges
    UnassociatedChargeRefunder.new.run
  end
end

# Table: payment_funding_transaction_stripe_card_strategies
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                  | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at          | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at          | timestamp with time zone |
#  originating_card_id | integer                  | NOT NULL
#  charge_json         | jsonb                    |
# Indexes:
#  payment_funding_transaction_stripe_card_strategies_pkey         | PRIMARY KEY btree (id)
#  payment_funding_transaction_stripe_card_strategies_originating_ | btree (originating_card_id)
# Foreign key constraints:
#  payment_funding_transaction_stripe_car_originating_card_id_fkey | (originating_card_id) REFERENCES payment_cards(id)
# Referenced By:
#  payment_funding_transactions | payment_funding_transactions_stripe_card_strategy_id_fkey | (stripe_card_strategy_id) REFERENCES payment_funding_transaction_stripe_card_strategies(id)
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
