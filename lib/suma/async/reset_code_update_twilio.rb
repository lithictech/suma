# frozen_string_literal: true

require "amigo/job"

class Suma::Async::ResetCodeUpdateTwilio
  extend Amigo::Job

  on "suma.member.resetcode.updated"

  def _perform(event)
    code = self.lookup_model(Suma::Member::ResetCode, event)
    case event.payload[1]
      when changed(:used, from: false, to: true)
        self.update_verification(code, "approved")
      when changed(:canceled, from: false, to: true)
        self.update_verification(code, "canceled")
    end
  end

  def update_verification(code, status)
    md = code.message_delivery
    return unless md &&
      md.transport_message_id.present? &&
      md.transport_service == "twilio-verify"
    verification_id = Suma::Message::Carrier::TwilioVerify.new.decode_message_id(md.transport_message_id)
    Suma::Twilio.update_verification(verification_id, status:)
  end
end
