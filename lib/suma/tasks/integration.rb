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
        lp = Suma::Lyft::Pass.new(
          email: Suma::Lyft.pass_email,
          authorization: Suma::Lyft.pass_authorization,
          org_id: Suma::Lyft.pass_org_id,
          account_id: Suma::Lyft.pass_account_id,
          vendor_service_rate: Suma::Vendor::ServiceRate.find!(Suma::Lyft.pass_vendor_service_rate_id),
        )
        lp.authenticate
        lp.sync_trips
      end
    end
  end
end
