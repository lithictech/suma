# frozen_string_literal: true

require "stripe"

require "suma"

module Suma::Stripe
  include Appydays::Configurable
  include Appydays::Loggable
  extend Suma::MethodUtilities

  class CustomerNotRegistered < Suma::InvalidPrecondition
    def initialize
      super("customer is not registered")
    end
  end

  configurable(:stripe) do
    setting :api_key, "sk_SET-ME-TO-SOMETHING", side_effect: ->(s) { Stripe.api_key = s }
    setting :public_key, "pk-ME-TO-SOMETHING"
    setting :api_version, "", side_effect: ->(s) { Stripe.api_version = s if s.present? }
    setting :app_url, "https://dashboard.stripe.com"

    after_configured do
      Stripe.logger = self.logger
    end
  end

  singleton_attr_accessor :unsafe_allow_transactions
  @unsafe_allow_transactions = false
  def self.check_transaction(db)
    return true if self.unsafe_allow_transactions
    if db.in_transaction?
      msg = "Should not call Stripe while in a transaction, because a rollback due to a later error " \
            "would lose the record of the Stripe change. Take this code out of a transaction, " \
            "or make some modifications."
      raise msg
    end
    return true
  end

  def self.default_metadata
    return {
      suma_api_version: Suma::VERSION,
    }
  end

  # @param [Stripe::CardError] e
  # @return [String]
  def self.localized_error_code(e)
    dc = e.json_body.dig(:error, :decline_code)
    return "card_generic" if dc.nil?
    return "card_permanent_failure" if PERMANENT_FAILURE.include?(dc)
    return "card_expired" if EXPIRED.include?(dc)
    return "card_contact_bank" if CONTACT_BANK.include?(dc)
    return "card_insufficient_funds" if NSF.include?(dc)
    return "card_try_again" if TRY_AGAIN.include?(dc)
    return "card_generic"
  end

  PERMANENT_FAILURE = Set.new(
    [
      "currency_not_supported",
      "do_not_honor",
      "incorrect_number",
      "incorrect_cvc",
      "incorrect_pin",
      "incorrect_zip",
      "invalid_cvc",
      "invalid_expiry_year",
      "invalid_number",
    ],
  ).freeze
  CONTACT_BANK = Set.new(
    [
      "approve_with_id",
      "call_issuer",
      "card_not_supported",
      "card_velocity_exceeded",
      "do_not_try_again",
      "invalid_account",
      "invalid_amount",
      "issuer_not_available",
      "new_account_information_available",
      "no_action_taken",
      "not_permitted",
      "pickup_card",
      "restricted_card",
      "revocation_of_all_authorizations",
      "revocation_of_authorization",
      "security_violation",
      "service_not_allowed",
      "stop_payment_order",
      "transaction_not_allowed",
    ],
  ).freeze
  TRY_AGAIN = Set.new(
    [
      "try_again_later",
    ],
  ).freeze
  EXPIRED = Set.new(
    [
      "expired_card",
    ],
  ).freeze
  NSF = Set.new(
    [
      "insufficient_funds",
      "withdrawal_count_limit_exceeded",
    ],
  ).freeze
end
