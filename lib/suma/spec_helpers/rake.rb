# frozen_string_literal: true

require "suma/tasks"
require "suma/spec_helpers"

module Suma::SpecHelpers::Rake
  def self.included(context)
    context.before(:all) do
      Suma::Tasks.load_all
    end
  end

  module_function def invoke_rake_task(name, *)
    Rake::Task.tasks.each(&:reenable)
    Rake::Task[name].invoke(*)
  ensure
    # If the task itself calls Rake[task].invoke, we need to make sure it gets reset.
    Rake::Task.tasks.each(&:reenable)
  end
end
