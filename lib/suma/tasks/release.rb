# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"
require "suma/tasks/db"
require "suma/tasks/sidekiq"

class Suma::Tasks::Release < Rake::TaskLib
  PASSWORD = "suma1234"

  def initialize
    super
    desc "Run the release script against the current environment."
    task :release do
      Rake::Task["db:migrate"].invoke
      Rake::Task["sidekiq:release"].invoke
    end

    namespace :release do
      desc "Set every user password to #{PASSWORD}."
      task :prepare_prod_db_for_testing do
        # Do NOT use load_app. We may have local migrations not applied to the dump,
        # and we'll error trying to load those models.
        require "suma/member"
        m = Suma::Member.new
        m.password = PASSWORD
        Sequel.connect(Suma::Postgres::Model.uri) do |conn|
          conn[:members].update(
            password_digest: m.password_digest,
            stripe_customer_json: nil,
          )
          conn[:members].where(email: "admin@lithic.tech").update(soft_deleted_at: nil)
        end
      end
    end
  end
end
