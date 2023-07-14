# frozen_string_literal: true

require "twilio-ruby"

require "appydays/configurable"
require "appydays/loggable"
require "suma/method_utilities"

module Suma::Twilio
  extend Suma::MethodUtilities
  include Appydays::Configurable
  include Appydays::Loggable

  singleton_attr_accessor :client

  configurable(:twilio) do
    setting :account_sid, "AC444test"
    setting :secret_id, "twilapikey_sid"
    setting :secret, "twilsecret"
    setting :verification_sid, "VA555test"

    after_configured do
      @client = Twilio::REST::Client.new(self.secret_id, self.secret, self.account_sid, nil, nil, self.logger)
    end
  end

  # Given a string representing a phone number, returns that phone number in E.164 format (+1XXX5550100).
  # Assumes all provided phone numbers are US numbers.
  # Does not check for invalid area codes.
  def self.format_phone(phone)
    return nil if phone.blank?
    return phone if /^\+1\d{10}$/.match?(phone)
    phone = phone.gsub(/\D/, "")
    return "+1" + phone if phone.size == 10
    return "+" + phone if phone.size == 11
  end

  def self.send_sms(from, to, body, attempt: 0)
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
      retry if e.code == 20_003
      raise(e)
    else
      # In some cases, we may get HTTP errors, not from Twilio itself.
      # Nothing we can do in these cases, so just retry.
      retry
    end
  end

  def self.send_verification(to, code:, locale:, channel: "sms")
    return self.client.verify.
        v2.
        services(self.verification_sid).
        verifications.
        create(to:, channel:, custom_code: code, locale:)
  end

  # Update the verification. Usually used to change the status (status: 'canceled' or 'approved') of reset codes.
  def self.update_verification(ve_id, kw)
    return self.client.verify.
        v2.
        services(self.verification_sid).
        verifications(ve_id).
        update(**kw)
  end
end
