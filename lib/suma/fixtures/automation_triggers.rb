# frozen_string_literal: true

require "suma/fixtures"
require "suma/automation_trigger"

module Suma::Fixtures::AutomationTriggers
  extend Suma::Fixtures

  fixtured_class Suma::AutomationTrigger

  base :automation_trigger do
    self.active_during ||=
      Faker::Number.between(from: 50, to: 2).days.ago..Faker::Number.between(from: 2, to: 50).days.from_now
    self.name ||= Faker::Lorem.sentence
    self.klass_name ||= "Suma::AutomationTrigger::Tester"
    self.topic ||= "*"
  end

  decorator :inactive do
    self.active_during_begin = 4.days.ago
    self.active_during_end = 2.days.ago
  end
end
