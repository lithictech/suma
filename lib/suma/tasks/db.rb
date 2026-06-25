# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::DB < Rake::TaskLib
  def initialize
    super
    namespace :db do
      desc "Drop all tables in the public schema."
      task :drop_tables do
        require "suma/postgres"
        Suma::Postgres.drop_all_tables
      end

      desc "Remove all data from application schemas"
      task :wipe do
        require "suma/postgres"
        Suma::Postgres.load_superclasses
        Suma::Postgres.each_model_class do |c|
          c.truncate(cascade: true)
        end
      end

      desc "Run migrations (rake db:migrate[<target>] to go to a specific version)"
      task :migrate, [:version] do |_, args|
        require "suma/postgres"
        Suma::Postgres.load_superclasses
        Suma::Postgres.run_all_migrations(target: args[:version]&.to_i)
      end

      desc "Re-create the database tables. Drop tables and migrate."
      task reset: ["db:drop_tables", "db:migrate"]
    end
  end

  def self.exec(db, cmd)
    Kernel.print cmd
    begin
      db.execute(cmd)
      Kernel.print "\n"
    rescue StandardError
      Kernel.print " (error)\n"
      raise
    end
  end
end
