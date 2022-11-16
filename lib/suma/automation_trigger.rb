# frozen_string_literal: true

require "suma/postgres/model"

# These are basically data-driven async jobs.
# Implementation classes in suma/automation_trigger do the work;
# these set up some parameters and call them for the heavy lifting.
#
# They will only run during active_during, so can be used to make
# time-dependent jobs, like adding ledgers or funds automatically when a user is registered.
#
# The `parameter` field is generally used to control the implementation,
# like specifying subsidy amounts or ledger names.
class Suma::AutomationTrigger < Suma::Postgres::Model(:automation_triggers)
  plugin :timestamps
  plugin :tstzrange_fields, :active_during

  dataset_module do
    def active_at(t)
      return self.where(Sequel.pg_range(:active_during).contains(Sequel.cast(t, :timestamptz)))
    end
  end

  def klass
    return self.klass_name.constantize
  end

  def run_with_payload(*payload)
    event = Amigo::Event.new("test", self.topic, payload)
    self.klass.run(self, event)
  end

  def self.load_implementations
    root = Pathname(__FILE__).dirname + "automation_trigger/"
    root.glob("*.rb").each do |path|
      base = path.basename.to_s[..-4]
      require("suma/automation_trigger/#{base}")
    end
  end
end

Suma::AutomationTrigger.load_implementations
