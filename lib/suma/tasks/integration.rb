# frozen_string_literal: true

require "rake/tasklib"

require "suma"

class Suma::Tasks::Integration < Rake::TaskLib
  def initialize
    super
    namespace :integration do
      desc "Run the LyftPass sync."
      task :lyftpass do
        require "suma"
        Suma.load_app
        require "suma/lyft/pass"
        Suma::Vendor::Service.where(mobility_vendor_adapter_key: "lyft_deeplink").update(charge_after_fulfillment: true)
        lp = Suma::Lyft::Pass.from_config
        lp.authenticate
        lp.sync_trips
      end
    end
  end
end
