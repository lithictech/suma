# frozen_string_literal: true

require "suma/signalwire"

class Suma::Message::Carrier::Signalwire < Suma::Message::Carrier
  def name = "signalwire"

  def send!(override_from:, to:, body:)
    from = override_from || Suma::Signalwire.transactional_number
    from = Suma::PhoneNumber.format_e164!(from)

    self.logger.info("send_signalwire_sms", to:)
    begin
      response = Suma::Signalwire.send_sms(from, to, body)
    rescue Twilio::REST::RestError => e
      if (logmsg = FATAL_SIGNALWIRE_ERROR_CODES[e.code])
        self.logger.warn(logmsg, to:, error: e.response.body)
        raise Suma::Message::UndeliverableRecipient, "Fatal Signalwire error: #{logmsg}"
      end
      raise(e)
    end
    sid = response.sid
    self.logger.debug("sent_signalwire_sms", response_body: response.to_s)
    return sid
  end

  # Signalwire errors will usually be re-raised, but in some cases, we want to handle them by not handling them,
  # like for invalid phone numbers which there's no point worrying about.
  # So we just log and delete the delivery.
  FATAL_SIGNALWIRE_ERROR_CODES = {
    "21217" => "signalwire_invalid_phone_number",
  }.freeze

  def external_link_for(msg_id) = Suma::Signalwire.message_log_url(msg_id)
end
