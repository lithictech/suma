# frozen_string_literal: true

require "suma/automation_trigger"

class Suma::AutomationTrigger::Tester < Suma::AutomationTrigger::Action
  class << self
    def runs = @runs ||= []
  end
  def run
    self.class.runs << self
  end
end
