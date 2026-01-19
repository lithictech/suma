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

  module_function def invoke_rake_task(name, *args, tail: [])
    argv = ["rake"]
    if args.empty?
      argv << name
    else
      argstr = args.map(&:to_s).join(",")
      argv << "#{name}[#{argstr}]"
    end
    argv.concat(tail)
    stub_const("ARGV", argv)
    Rake::Task.tasks.each(&:reenable)
    Rake::Task[name].invoke(*args)
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

  module_function def create_rake_task(args: [], &block)
    taskname = "testtask_#{SecureRandom.hex(8)}"
    cls = Class.new(Rake::TaskLib) do
      define_method :initialize do
        super()
        task(taskname, args, &block)
      end
    end
    cls.new
    return Rake::Task.tasks.find { |t| t.name == taskname }
  end
end
