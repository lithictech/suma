# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Analytics < Rake::TaskLib
  def initialize
    super
    namespace :analytics do
      desc "Truncate all analytics tables."
      task :truncate do
        require "suma/postgres"
        Suma::Postgres.load_models
        Suma::Analytics.truncate_all
      end

      desc "Process all transactional data into analytics data."
      task :import do
        require "suma/postgres"
        Suma::Postgres.load_models
        Suma::Analytics.reimport_all
      end
    end
  end
end
