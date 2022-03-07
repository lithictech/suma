# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::DB < Rake::TaskLib
  def initialize
    super()
    namespace :db do
      desc "Drop all tables in the public schema."
      task :drop_tables do
        require "suma/postgres"
        Suma::Postgres.load_superclasses
        Suma::Postgres.each_model_superclass do |sc|
          sc.db[:pg_tables].where(schemaname: "public").each do |tbl|
            self.exec(sc.db, "DROP TABLE #{tbl[:tablename]} CASCADE")
          end
        end
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

  def exec(db, cmd)
    print cmd
    begin
      db.execute(cmd)
      print "\n"
    rescue StandardError
      print " (error)\n"
      raise
    end
  end
end
