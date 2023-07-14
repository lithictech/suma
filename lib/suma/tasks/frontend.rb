# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Frontend < Rake::TaskLib
  def initialize
    super()
    namespace :frontend do
      task :build_webapp do
        self.runcmd("bin/build-webapp")
      end
      task :build_adminapp do
        self.runcmd("bin/build-adminapp")
      end
    end
  end

  def runcmd(s)
    require "English"
    `#{s}`
    ps = $CHILD_STATUS
    return if ps.exitstatus.zero?
    puts "Non-zero exit status: #{ps.inspect}"
    exit(ps.exitstatus)
  end
end
