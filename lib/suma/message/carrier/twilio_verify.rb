# frozen_string_literal: true

require "appydays/loggable"
require "suma/twilio"

class Suma::Message::Carrier::TwilioVerify < Suma::Message::Carrier
  def name = "twilio_verify"

  def send!(to:, code:, locale:, channel:)
    begin
      response = Suma::Twilio.send_verification(to, code:, locale:, channel:)
    rescue Twilio::REST::RestError => e
      if (logmsg = FATAL_TWILIO_ERROR_CODES[e.code])
        self.logger.warn(logmsg, error: e.response.body)
        raise Suma::Message::UndeliverableRecipient, "Fatal Twilio error: #{logmsg}"
      end
      raise e
    end
    return self.encode_message_id(response.sid, response.send_code_attempts.length.to_s)
  end

  FATAL_TWILIO_ERROR_CODES = {
    60_200 => "twilio_invalid_phone_number",
  }.freeze

  # Given the response from the verification service (like a Twilio response),
  # return a suitable string for the delivery's +transport_message_id+ column.
  # The value returned from this must be parseable back into a verification service ID
  # in +from_transport_message_id+.
  # @return [String]
  def encode_message_id(sid, sid_disambiguator)
    vtmid = "#{sid}-#{sid_disambiguator}"
    return vtmid
  end

  # Given a value from +encode_message_id+,
  # return an ID that can be used for the verification service.
  # @param tmid [String]
  # @return [String]
  def decode_message_id(tmid)
    idpart = tmid.gsub(/-\d+$/, "")
    return idpart
  end

  def external_link_for(msg_id) = Suma::Twilio.verification_log_url(msg_id)
  def can_fetch_details? = true

  def fetch_message_details(msg_id)
    Suma.assert do
      [msg_id == self.decode_message_id(msg_id), "message id should have been decoded"]
    end
    ve = Suma::Twilio.fetch_verification(msg_id)
    return ve.instance_variable_get(:@properties)
  end
end
