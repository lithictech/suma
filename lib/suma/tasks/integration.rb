# frozen_string_literal: true

require "rake/tasklib"

require "suma"

class Suma::Tasks::Integration < Rake::TaskLib
  def initialize
    super
    namespace :integration do
      desc "Run the LyftPass auth and access to make sure it's working."
      task :lyftpass do
        require "suma"
        Suma.load_app
        require "suma/lyft/pass"
        lp = Suma::Lyft::Pass.new(
          email: Suma::Lyft.pass_email,
          authorization: Suma::Lyft.pass_authorization,
          org_id: Suma::Lyft.pass_org_id,
          account_id: Suma::Lyft.pass_account_id,
        )
        lp.authenticate
        puts lp.fetch_rides
      end
    end
  end
end
