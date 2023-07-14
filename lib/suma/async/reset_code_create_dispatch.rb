# frozen_string_literal: true

require "amigo/job"

class Suma::Async::ResetCodeCreateDispatch
  extend Amigo::Job

  on "suma.member.resetcode.created"

  def _perform(event)
    code = self.lookup_model(Suma::Member::ResetCode, event)
    Suma::Idempotency.once_ever.under_key("reset-code-#{code.member_id}-#{code.id}") do
      code.dispatch_message
    end
  end

  Amigo.register_job(self)
end
