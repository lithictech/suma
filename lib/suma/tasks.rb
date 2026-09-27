# frozen_string_literal: true

require "rake/tasklib"

require "suma"

module Suma::Tasks
  class << self
    def load_all
      return if @loaded
      pattern = Suma::SELF_DIR.join("suma", "tasks", "*.rb")
      Dir.glob(pattern).each { |path| require path }
      Rake::TaskLib.descendants.each do |task|
        next unless task.name&.start_with?("Suma::Tasks")
        task.new
      end
      @loaded = true
    end
  end
end
