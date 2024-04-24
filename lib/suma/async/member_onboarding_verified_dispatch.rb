# frozen_string_literal: true

require "amigo/job"

class Suma::Async::MemberOnboardingVerifiedDispatch
  extend Amigo::Job

  on "suma.member.updated"

  def _perform(event)
    member = self.lookup_model(Suma::Member, event)
    # If a user ends up being un-verified by the time this job runs,
    # do not send a verified message (since it would be inaccurate).
    return unless member.onboarding_verified?
    # If someone was verified a while ago, but we toggle the verified switch,
    # we don't want to send them a message (cannot assume idempotency lasts forever).
    return if member.onboarding_verified_at < 7.days.ago
    case event.payload[1]
      when changed(:onboarding_verified_at, from: nil)
        Suma::Idempotency.once_ever.under_key("member-#{member.id}-onboarding-verified-dispatch") do
          msg = Suma::Messages::SingleValue.new(
            "",
            "onboarding_verification",
            Suma.app_url,
          )
          member.message_preferences!.dispatch(msg)
        end
    end
  end

  Amigo.register_job(self)
end
