# frozen_string_literal: true

require "appydays/loggable"
require "suma/twilio"

class Suma::Message::OtpSmsTransport < Suma::Message::Transport
  include Appydays::Loggable

  class UnknownVerificationId < StandardError; end

  def initialize
    super
    @smstransport = Suma::Message::SmsTransport.new
  end

  def service = "twilio-verify-sms"
  def type = :otp_sms
  def supports_layout? = false

  def recipient(to) = @smstransport.recipient(to)
  def allowlisted?(delivery) = @smstransport.allowlisted?(delivery)

  def add_bodies(delivery, content)
    bodies = []
    bodies << delivery.add_body(content:, mediatype: "text/plain")
    return bodies
  end

  def send!(delivery)
    to_phone = Suma::PhoneNumber.format_e164(delivery.to)
    raise Suma::Message::Error, "Could not format phone number" if
      to_phone.nil?

    raise Suma::Message::UndeliverableRecipient, "Number '#{to_phone}' not allowlisted" unless
      @smstransport.allowlisted_phone?(to_phone)

    code = delivery.bodies.first.content.strip
    begin
      response = Suma::Twilio.send_verification(to_phone, code:, locale: delivery.template_language, channel: "sms")
    rescue Twilio::REST::RestError => e
      if (logmsg = FATAL_TWILIO_ERROR_CODES[e.code])
        self.logger.warn(logmsg, phone: to_phone, body: code, error: e.response.body)
        raise Suma::Message::UndeliverableRecipient, "Fatal Twilio error: #{logmsg}"
      end
      raise(e)
    end

    return self.to_transport_message_id(response.sid, response.send_code_attempts.length.to_s)
  end

  FATAL_TWILIO_ERROR_CODES = {
    60_200 => "twilio_invalid_phone_number",
  }.freeze

  # Given the response from the verification service (like a Twilio response),
  # return a suitable string for the delivery's +transport_message_id+ column.
  # The value returned from this must be parseable back into a verification service ID
  # in +from_transport_message_id+.
  # @return [String]
  def to_transport_message_id(sid, sid_disambiguator)
    vtmid = "#{sid}-#{sid_disambiguator}"
    return vtmid
  end

  # Given a +transport_message_id+, return an ID that can be used for the verification service.
  # If the ID cannot be verified, raise an error.
  # @param tmid [String]
  # @return [String]
  def from_transport_message_id(tmid)
    idpart = tmid.rpartition("-")[0]
    return idpart
  end
end
