# frozen_string_literal: true

require "amigo/job"

class Suma::Async::AutomationTriggerRunner
  extend Amigo::Job

  on "suma.*"

  def _perform(event)
    Suma::AutomationTrigger.active_at(Time.now).each do |at|
      next unless File.fnmatch(at.topic, event.name, File::FNM_EXTGLOB)
      at.klass.new(at, event).run
    end
  end

  Amigo.register_job(self)
end
