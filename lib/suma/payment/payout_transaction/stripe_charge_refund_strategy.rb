# frozen_string_literal: true

require "suma/stripe"
require "suma/payment/payout_transaction/strategy"
require "suma/postgres/model"

class Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy <
  Suma::Postgres::Model(:payment_payout_transaction_stripe_charge_refund_strategies)
  include Suma::Payment::PayoutTransaction::Strategy

  # Don't use a NotImplementedError since that's used for abstract methods.
  class WorkInProgressImplementation < StandardError; end

  one_to_one :payout_transaction, class: "Suma::Payment::PayoutTransaction"

  def short_name
    return "Stripe Card Payout"
  end

  def check_validity
    return []
  end

  def ready_to_send_funds?
    return true
  end

  def refund_id = self.refund_json&.fetch("id")

  def send_funds
    return false if self.refund_id.present? && self.refund_json["status"] == "succeeded"
    raise WorkInProgressImplementation, "we currently only support succeeded refunds already created in Stripe"
  end

  def funds_settled?
    raise Suma::InvalidPrecondition, "refund_json must be set" if self.refund_json.nil?
    return self.refund_json["status"] == "succeeded"
  end

  private def refund_id_set!
    return if self.refund_id.present?
    msg = "Stripe charge idid not set after API call from #{self.class.name}[#{self.id}]. " \
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
end
