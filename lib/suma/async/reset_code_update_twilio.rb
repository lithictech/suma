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
    return unless
      # It's possible for a code to be expired before we have even sent the delivery
      md &&
        # email codes aren't using twilio verify, at least not yet (and probably never)
        md.transport_type == "sms" &&
        # deliveries can potentially be aborted therefore a having nil message id
        md.transport_message_id &&
        # We can send verifications using alternative templates; only the verification template uses
        # the 'send via twilio verify' logic in SmsTransport, so we only update twilio when we use that template.
        Suma::Message::SmsTransport.verification_delivery?(md)
    verification_id = Suma::Message::SmsTransport.transport_message_id_to_verification_id(md.transport_message_id)
    begin
      Suma::Twilio.update_verification(verification_id, status:)
    rescue Twilio::REST::RestError => e
      # 404 means twilio has approved, expired or invalidated the code already
      # https://www.twilio.com/docs/verify/api/verification-check#check-a-verification
      nil if e.code === 404
    end
  end
end
