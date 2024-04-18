# frozen_string_literal: true

require "amigo/job"
require "suma/messages/onboarding_verification"

class Suma::Async::MemberOnboardingVerifiedDispatch
  extend Amigo::Job

  on "suma.member.updated"

  def _perform(event)
    member = self.lookup_model(Suma::Member, event)
    return unless member.onboarding_verified?
    case event.payload[1]
      when changed(:onboarding_verified_at, from: nil)
        Suma::Idempotency.once_ever.under_key("member-#{member.id}-onboarding-verified-dispatch") do
          msg = Suma::Messages::OnboardingVerification.new(member)
          member.message_preferences!.dispatch(msg)
        end
    end
  end

  Amigo.register_job(self)
end
