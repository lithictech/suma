# frozen_string_literal: true

require "suma/automation_trigger"

class Suma::AutomationTrigger::AutoOnboard
  def self.run(instance, event)
    member = Suma::Member.find!(event.payload.first)
    instance.db.transaction do
      member.lock!
      member.onboarding_verified_at ||= Time.now
      member.save_changes
    end
  end
end
