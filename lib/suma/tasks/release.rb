# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Release < Rake::TaskLib
  PASSWORD = "suma1234"

  def initialize
    super
    desc "Run the release script against the current environment."
    task :release do
      Rake::Task["db:migrate"].invoke
    end

    namespace :release do
      desc "Set every user password to #{PASSWORD}."
      task :prepare_prod_db_for_testing do
        Suma.load_app
        m = Suma::Member.new
        m.password = PASSWORD
        Suma::Member.dataset.update(
          password_digest: m.password_digest,
          stripe_customer_json: nil,
          frontapp_contact_id: "",
        )
        Suma::Member.where(email: "admin@lithic.tech").update(soft_deleted_at: nil)
      end
    end
  end
end
