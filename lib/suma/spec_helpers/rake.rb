# frozen_string_literal: true

require "suma/tasks"
require "suma/spec_helpers"

module Suma::SpecHelpers::Rake
  def self.included(context)
    context.before(:all) do
      Suma::Tasks.load_all
    end
    context.around(:each) do |example|
      next example.run unless example.metadata[:redirect]
      stdout = named_stdout
      stderr = named_stderr
      orig_stdout = $stdout
      orig_stderr = $stderr
      $stdout = stdout
      $stderr = stderr
      begin
        example.run
      ensure
        $stdout = orig_stdout
        $stderr = orig_stderr
      end
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
