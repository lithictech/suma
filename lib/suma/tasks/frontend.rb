# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Frontend < Rake::TaskLib
  def initialize
    super()
    namespace :frontend do
      task :build_webapp do
        puts `bin/build-webapp`
      end
      task :build_adminapp do
        puts `bin/build-adminapp`
      end
    end
  end
end
