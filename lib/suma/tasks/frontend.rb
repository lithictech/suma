# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Frontend < Rake::TaskLib
  def initialize
    super()
    namespace :frontend do
      task :build_webapp do
        release = "sumaweb@"
        release += Suma::RELEASE.include?("unknown") ? Suma::VERSION : Suma::RELEASE
        ENV["REACT_APP_RELEASE"] = release
        puts `bin/build-webapp`
      end
    end
  end
end
