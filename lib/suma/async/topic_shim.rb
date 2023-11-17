# frozen_string_literal: true

require "suma/async"

# Re-publish certain events as other events.
# Used to shim other parts of the backend, like turning a suma.member.updated event
# of the onboarding_verified_at field, into a suma.member.verified event.
class Suma::Async::TopicShim
  extend Amigo::Job

  on "*"

  def _perform(event)
    case event.name
        when "suma.member.updated"
          member = self.lookup_model(Suma::Member, event)
          case event.payload[1]
              when changed(:onboarding_verified_at, from: nil)
                Amigo.publish("suma.member.verified", member.id)
            end
      end
  end
end
