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

  def self.build_metadata(relations=[])
    h = {
      suma_api_version: Suma::VERSION,
    }
    relations.select(&:itself).each do |r|
      ns = r.class.name.split("::").last.underscore
      h[:"suma_#{ns}_id"] = r.id
      h[:"suma_#{ns}_name"] = r.name if r.respond_to?(:name) && r.name.present?
    end
    return h
  end

  # @param [Stripe::CardError] e
  # @return [String]
  def self.localized_error_code(e)
    code = e.json_body.dig(:error, :decline_code) || e.code
    return "card_generic" if code.nil?
    code = code.to_sym
    localized = ERRORS_FOR_CODES.fetch(code.to_sym, :card_generic)
    return localized.to_s
  end

  # Map Stripe error and decline codes to localized codes.
  # Stripe decline codes https://stripe.com/docs/declines/codes
  # and error codes https://stripe.com/docs/error-codes
  # generally use the same values for similar errors,
  # so we don't need to keep two separate maps.
  ERRORS_FOR_CODES = {
    incorrect_number: :card_invalid_number,
    invalid_number: :card_invalid_number,

    invalid_expiry_month: :card_invalid_expiry,
    invalid_expiry_year: :card_invalid_expiry,

    incorrect_cvc: :card_invalid_cvc,
    invalid_cvc: :card_invalid_cvc,

    incorrect_zip: :card_invalid_zip,

    currency_not_supported: :card_permanent_failure,
    do_not_honor: :card_permanent_failure,
    incorrect_pin: :card_permanent_failure,

    approve_with_id: :card_contact_bank,
    call_issuer: :card_contact_bank,
    card_not_supported: :card_contact_bank,
    card_velocity_exceeded: :card_contact_bank,
    do_not_try_again: :card_contact_bank,
    invalid_account: :card_contact_bank,
    invalid_amount: :card_contact_bank,
    issuer_not_available: :card_contact_bank,
    new_account_information_available: :card_contact_bank,
    no_action_taken: :card_contact_bank,
    not_permitted: :card_contact_bank,
    pickup_card: :card_contact_bank,
    restricted_card: :card_contact_bank,
    revocation_of_all_authorizations: :card_contact_bank,
    revocation_of_authorization: :card_contact_bank,
    security_violation: :card_contact_bank,
    service_not_allowed: :card_contact_bank,
    stop_payment_order: :card_contact_bank,
    transaction_not_allowed: :card_contact_bank,

    try_again_later: :card_try_again_later,

    expired_card: :card_expired,

    insufficient_funds: :card_insufficient_funds,
    withdrawal_count_limit_exceeded: :card_insufficient_funds,
  }.freeze
end
