# frozen_string_literal: true

require "amigo/job"

# When a member's membership is verified,
# make sure they are marked onboarding verified,
# so we don't have to update things in two places.
class Suma::Async::MembershipVerifiedVerifyOnboarding
  extend Amigo::Job

  on "suma.organization.membership.updated"

  def _perform(event)
    membership = self.lookup_model(Suma::Organization::Membership, event)
    case event.payload[1]
      when changed(:verified_organization_id, from: nil)
        membership.member.onboarding_verified = true
        membership.member.save_changes
    end
  end
end
