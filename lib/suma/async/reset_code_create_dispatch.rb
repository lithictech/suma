# frozen_string_literal: true

require "amigo/job"
require "suma/messages/verification"

class Suma::Async::ResetCodeCreateDispatch
  extend Amigo::Job

  on "suma.customer.resetcode.created"

  def _perform(event)
    code = self.lookup_model(Suma::Member::ResetCode, event)
    Suma::Idempotency.once_ever.under_key("reset-code-#{code.customer_id}-#{code.id}") do
      msg = Suma::Messages::Verification.new(code)
      case code.transport
        when "sms"
          msg.dispatch_sms(code.customer)
        when "email"
          msg.dispatch_email(code.customer)
      else
          raise "Unknown transport for #{code.inspect}"
      end
    end
  end

  Amigo.register_job(self)
end
