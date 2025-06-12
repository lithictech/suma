# frozen_string_literal: true

require "twilio-ruby"

require "appydays/configurable"
require "appydays/loggable"

module Suma::Twilio
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:twilio) do
    setting :account_sid, "AC444test"
    setting :secret_id, "twilapikey_sid"
    setting :secret, "twilsecret"
    setting :verification_sid, "VA555test"

    after_configured do
      @client = Twilio::REST::Client.new(self.secret_id, self.secret, self.account_sid, nil, nil, self.logger)
    end
  end

  class << self
    attr_accessor :client
  end

  def self.send_verification(to, code:, locale:, channel:)
    return self.client.verify.
        v2.
        services(self.verification_sid).
        verifications.
        create(to:, channel:, custom_code: code, locale:)
  end

  # Update the verification. Usually used to change the status (status: 'canceled' or 'approved') of reset codes.
  def self.update_verification(ve_id, kw)
    response = self.client.verify.
      v2.
      services(self.verification_sid).
      verifications(ve_id).
      update(**kw)
    return response
  rescue Twilio::REST::RestError => e
    # ignores 20404s, it means twilio has approved, expired or invalidated the code already
    # https://www.twilio.com/docs/verify/api/verification-check#check-a-verification
    raise(e) unless IGNORE_TWILIO_ERROR_CODES[e.code]
  end

  IGNORE_TWILIO_ERROR_CODES = {
    20_404 => "twilio_resource_not_found",
  }.freeze
end
