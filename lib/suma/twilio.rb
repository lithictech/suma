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
    setting :auth_token, "ac45test"

    after_configured do
      @client = Twilio::REST::Client.new(self.account_sid, self.auth_token)
    end
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
end
