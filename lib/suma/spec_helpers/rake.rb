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

  class NamedIO < StringIO
    attr_accessor :path
  end

  def named_io(path)
    io = NamedIO.new
    io.path = path
    return io
  end

  def named_stdout = named_io("<STDOUT>")
  def named_stderr = named_io("<STDERR>")
end
