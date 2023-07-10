# frozen_string_literal: true

require "suma/automation_trigger"

class Suma::AutomationTrigger::AutoOnboard < Suma::AutomationTrigger::Action
  def run
    member = Suma::Member.find!(self.event.payload.first)
    self.automation_trigger.db.transaction do
      member.lock!
      member.onboarding_verified_at ||= Time.now
      member.save_changes
    end
  end
end
