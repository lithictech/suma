# frozen_string_literal: true

require "rake/tasklib"

require "suma"

module Suma::Tasks
  class << self
    def load_all
      return if @loaded
      pattern = File.join(Pathname(__FILE__).dirname, "tasks", "*.rb")
      Gem.find_files(pattern).each do |path|
        require path
      end
      Rake::TaskLib.descendants.each do |task|
        next unless task.name.start_with?("Suma::Tasks")
        task.new
      end
      @loaded = true
    end
  end
end
