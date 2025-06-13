# frozen_string_literal: true

require "signalwire"

require "appydays/configurable"
require "appydays/loggable"

module Suma::Signalwire
  include Appydays::Configurable
  include Appydays::Loggable

  SPLIT_WORDS = ->(s) { s.split.map(&:strip) }

  SMS_COST_PER_SEGMENT = BigDecimal("0.00415")

  configurable(:signalwire) do
    setting :api_token, "sw-test-token"
    setting :project_id, "sw-test-project"
    setting :space_url, "sumafaketest.signalwire.com"
    setting :transactional_number, "15554443333"
    setting :marketing_number, ""
    setting :message_marketing_sms_unsubscribe_keywords, ["STOP", "UNSUBSCRIBE", "ALTO"], convert: SPLIT_WORDS
    setting :message_marketing_sms_resubscribe_keywords, ["START", "RESUBSCRIBE", "COMENZAR"], convert: SPLIT_WORDS
    setting :message_marketing_sms_help_keywords, ["HELP", "AYUDA"], convert: SPLIT_WORDS
    # When provisioning phone numbers (see +Suma::AnonProxy::Relay::Signalwire+),
    # what query parameters should be used to bias the search?
    # See https://developer.signalwire.com/rest/signalwire-rest/endpoints/space/search-available-phone-numbers#request
    setting :phone_number_provision_query, "city=Portland&region=OR"

    after_configured do
      @client = Signalwire::REST::Client.new(self.project_id, self.api_token, signalwire_space_url: self.space_url)
      @client.logger = self.logger
    end
  end

  class << self
    attr_reader :client

    # @!attribute client
    # @return [Signalwire::REST::Client]
  end

  RETRIABLE_ERROR_CODES = Set.new([
                                    "53603",
                                  ])

  # @param from [String]
  # @param to [String]
  # @param body [String]
  def self.send_sms(from, to, body, attempt: 0)
    raise ArgumentError, ":from must be in E164 format" unless from.start_with?("+")
    raise ArgumentError, ":to must be in E164 format" unless to.start_with?("+")
    attempt += 1
    response = self.client.messages.create(
      from:,
      to:,
      body:,
    )
    return response
  rescue Twilio::REST::TwilioError => e
    # If we're out of attempts, always raise no matter the underlying error.
    raise(e) if attempt >= 2
    if e.is_a?(Twilio::REST::RestError)
      # Some REST errors are transient and retriable, but most are not
      retry if e.code == "53603"
      raise(e)
    else
      # In some cases, we may get HTTP errors, not from Twilio itself.
      # Nothing we can do in these cases, so just retry.
      retry
    end
  end

  def self.make_rest_request(method, url, body: nil, headers: {}, **options)
    headers["Content-Type"] ||= "application/json"
    body = body.to_json if body
    options[:basic_auth] = {username: self.project_id, password: self.api_token}
    options[:logger] = self.logger
    full_url = "https://#{self.space_url}#{url}"
    Suma::Http.execute(method, full_url, body:, headers:, **options)
  end

  def self.message_log_url(id) = "https://#{self.space_url}/logs/messages/#{id}"
end
