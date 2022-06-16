# frozen_string_literal: true

require "amigo/job"
require "suma/messages/verification"

class Suma::Async::ResetCodeCreateDispatch
  extend Amigo::Job

  on "suma.member.resetcode.created"

  def _perform(event)
    code = self.lookup_model(Suma::Member::ResetCode, event)
    Suma::Idempotency.once_ever.under_key("reset-code-#{code.member_id}-#{code.id}") do
      msg = Suma::Messages::Verification.new(code)
      case code.transport
        when "sms"
          msg.dispatch_sms(code.member)
        when "email"
          msg.dispatch_email(code.member)
      else
          raise "Unknown transport for #{code.inspect}"
      end
    end
  end

  Amigo.register_job(self)
end
