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
    end
  end
end
